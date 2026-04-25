require_relative '../../spec_helper'
require 'active_record'
require 'annotate/sti_columns'

describe Annotate::StiColumns do
  before(:each) do
    # Reset the models_loaded flag between tests
    described_class.instance_variable_set(:@models_loaded, true)
  end

  def mock_ar_class(name:, table_name:, superclass: ActiveRecord::Base, validators: [], belongs_to: [], enums: {}, stored_attrs: {}, column_names: [], inheritance_column: 'type', descendants: [], subclasses: nil)
    klass = double(name)
    allow(klass).to receive(:name).and_return(name)
    allow(klass).to receive(:table_name).and_return(table_name)
    allow(klass).to receive(:superclass).and_return(superclass)
    allow(klass).to receive(:<).with(ActiveRecord::Base).and_return(true)
    allow(klass).to receive(:column_names).and_return(column_names)
    allow(klass).to receive(:inheritance_column).and_return(inheritance_column)
    allow(klass).to receive(:descendants).and_return(descendants)
    allow(klass).to receive(:subclasses).and_return(subclasses || descendants)

    allow(klass).to receive(:validators).and_return(
      validators.map { |attr| double('Validator', attributes: [attr]) }
    )
    allow(klass).to receive(:reflect_on_all_associations).with(:belongs_to).and_return(
      belongs_to.map { |fk| double('Association', foreign_key: fk, name: fk.to_s.sub(/_id$/, ''), polymorphic?: false) }
    )
    allow(klass).to receive(:defined_enums).and_return(enums)
    allow(klass).to receive(:stored_attributes).and_return(stored_attrs)

    klass
  end

  def mock_column(name)
    double('Column', name: name.to_s)
  end

  describe '.columns_referenced_in' do
    it 'collects columns from validators' do
      klass = mock_ar_class(name: 'Car', table_name: 'vehicles', validators: [:num_doors, :color])
      expect(described_class.columns_referenced_in(klass)).to eq Set.new(%w[num_doors color])
    end

    it 'collects foreign keys from belongs_to associations' do
      klass = mock_ar_class(name: 'Car', table_name: 'vehicles', belongs_to: [:manufacturer_id])
      expect(described_class.columns_referenced_in(klass)).to eq Set.new(%w[manufacturer_id])
    end

    it 'collects enum columns' do
      klass = mock_ar_class(name: 'Car', table_name: 'vehicles', enums: { 'fuel_type' => { gas: 0, diesel: 1 } })
      expect(described_class.columns_referenced_in(klass)).to eq Set.new(%w[fuel_type])
    end

    it 'collects stored attribute columns' do
      klass = mock_ar_class(name: 'Car', table_name: 'vehicles', stored_attrs: { settings: [:color, :theme] })
      expect(described_class.columns_referenced_in(klass)).to eq Set.new(%w[settings])
    end

    it 'combines all sources' do
      klass = mock_ar_class(name: 'Car', table_name: 'vehicles',
                            validators: [:name], belongs_to: [:owner_id],
                            enums: { 'status' => {} }, stored_attrs: { prefs: [:lang] })
      expect(described_class.columns_referenced_in(klass)).to eq Set.new(%w[name owner_id status prefs])
    end
  end

  describe '.columns_owned_by' do
    it 'returns columns referenced by subclass but not by superclass' do
      vehicle = mock_ar_class(name: 'Vehicle', table_name: 'vehicles', validators: [:name])
      car = mock_ar_class(name: 'Car', table_name: 'vehicles', superclass: vehicle,
                          validators: [:name, :num_doors])

      expect(described_class.columns_owned_by(car)).to eq Set.new(%w[num_doors])
    end

    it 'returns empty set for non-STI classes' do
      klass = mock_ar_class(name: 'User', table_name: 'users', superclass: ActiveRecord::Base)
      expect(described_class.columns_owned_by(klass)).to eq Set.new
    end

    it 'returns empty set when subclass references no new columns' do
      vehicle = mock_ar_class(name: 'Vehicle', table_name: 'vehicles', validators: [:name])
      car = mock_ar_class(name: 'Car', table_name: 'vehicles', superclass: vehicle,
                          validators: [:name])

      expect(described_class.columns_owned_by(car)).to eq Set.new
    end
  end

  describe '.partition' do
    let(:id_col) { mock_column(:id) }
    let(:type_col) { mock_column(:type) }
    let(:name_col) { mock_column(:name) }
    let(:num_doors_col) { mock_column(:num_doors) }
    let(:payload_col) { mock_column(:payload_capacity) }
    let(:color_col) { mock_column(:color) }
    let(:battery_col) { mock_column(:battery_kwh) }
    let(:settings_col) { mock_column(:settings) }

    let(:all_columns) { [id_col, type_col, name_col, num_doors_col, payload_col, color_col] }

    context 'for a non-STI class' do
      it 'returns a single group with no label' do
        klass = mock_ar_class(name: 'User', table_name: 'users',
                              column_names: %w[id name])
        cols = [id_col, name_col]

        result = described_class.partition(klass, cols)

        expect(result).to eq [[nil, cols]]
      end
    end

    context 'for an STI subclass' do
      it 'separates owned columns from shared columns' do
        vehicle = mock_ar_class(name: 'Vehicle', table_name: 'vehicles', validators: [:name],
                                column_names: %w[id type name num_doors payload_capacity color])
        car = mock_ar_class(name: 'Car', table_name: 'vehicles', superclass: vehicle,
                            validators: [:name, :num_doors])

        result = described_class.partition(car, all_columns)

        labels = result.map(&:first)
        expect(labels).to eq ['Vehicle columns', 'Car columns']

        vehicle_col_names = result[0][1].map { |c| c.name }
        car_col_names = result[1][1].map { |c| c.name }
        expect(vehicle_col_names).to include('id', 'type', 'name', 'payload_capacity', 'color')
        expect(car_col_names).to eq ['num_doors']
      end

      it 'returns only shared group when subclass owns no columns' do
        vehicle = mock_ar_class(name: 'Vehicle', table_name: 'vehicles', validators: [:name])
        car = mock_ar_class(name: 'Car', table_name: 'vehicles', superclass: vehicle,
                            validators: [:name])
        cols = [id_col, type_col, name_col]

        result = described_class.partition(car, cols)

        expect(result.length).to eq 1
        expect(result[0][0]).to eq 'Vehicle columns'
        expect(result[0][1]).to eq cols
      end

      it 'warns when subclass owns no columns' do
        vehicle = mock_ar_class(name: 'Vehicle', table_name: 'vehicles', validators: [:name])
        car = mock_ar_class(name: 'Car', table_name: 'vehicles', superclass: vehicle,
                            validators: [:name])
        cols = [id_col, type_col, name_col]

        expect($stderr).to receive(:puts).with(/could not determine which columns belong to Car/)
        expect($stderr).to receive(:puts).with(/Add validations/)

        described_class.partition(car, cols)
      end
    end

    context 'for an STI base class' do
      it 'groups columns by owning subclass' do
        vehicle = mock_ar_class(name: 'Vehicle', table_name: 'vehicles', validators: [:name],
                                column_names: %w[id type name num_doors payload_capacity color])
        car = mock_ar_class(name: 'Car', table_name: 'vehicles', superclass: vehicle,
                            validators: [:name, :num_doors])
        truck = mock_ar_class(name: 'Truck', table_name: 'vehicles', superclass: vehicle,
                              validators: [:name, :payload_capacity])
        allow(vehicle).to receive(:descendants).and_return([car, truck])

        result = described_class.partition(vehicle, all_columns)

        labels = result.map(&:first)
        expect(labels).to eq ['Vehicle columns', 'Car columns', 'Truck columns']

        base_col_names = result[0][1].map { |c| c.name }
        expect(base_col_names).to include('id', 'type', 'name', 'color')
        expect(base_col_names).not_to include('num_doors', 'payload_capacity')
      end

      it 'puts unclaimed columns in the base group' do
        vehicle = mock_ar_class(name: 'Vehicle', table_name: 'vehicles', validators: [],
                                column_names: %w[id type name color])
        car = mock_ar_class(name: 'Car', table_name: 'vehicles', superclass: vehicle,
                            validators: [:num_doors])
        allow(vehicle).to receive(:descendants).and_return([car])

        cols = [id_col, type_col, name_col, color_col, num_doors_col]
        result = described_class.partition(vehicle, cols)

        base_col_names = result[0][1].map { |c| c.name }
        expect(base_col_names).to include('id', 'type', 'name', 'color')
      end

      it 'assigns a column to the first subclass that claims it' do
        vehicle = mock_ar_class(name: 'Vehicle', table_name: 'vehicles', validators: [],
                                column_names: %w[id type color])
        car = mock_ar_class(name: 'Car', table_name: 'vehicles', superclass: vehicle,
                            validators: [:color])
        truck = mock_ar_class(name: 'Truck', table_name: 'vehicles', superclass: vehicle,
                              validators: [:color])
        allow(vehicle).to receive(:descendants).and_return([car, truck])

        cols = [id_col, type_col, color_col]
        result = described_class.partition(vehicle, cols)

        # Car comes first alphabetically, so it claims 'color'
        car_group = result.find { |label, _| label == 'Car columns' }
        truck_group = result.find { |label, _| label == 'Truck columns' }
        expect(car_group[1].map { |c| c.name }).to include('color')
        expect(truck_group).to be_nil
      end

      it 'warns when no columns can be assigned to subclasses' do
        vehicle = mock_ar_class(name: 'Vehicle', table_name: 'vehicles', validators: [:name],
                                column_names: %w[id type name])
        car = mock_ar_class(name: 'Car', table_name: 'vehicles', superclass: vehicle,
                            validators: [:name])
        allow(vehicle).to receive(:descendants).and_return([car])

        expect($stderr).to receive(:puts).with(/found STI subclasses for Vehicle but no columns could be assigned/)
        expect($stderr).to receive(:puts).with(/Add validations/)

        described_class.partition(vehicle, [id_col, type_col, name_col])
      end

      it 'assigns stored attributes backing columns to the subclass correctly' do
        vehicle = mock_ar_class(name: 'Vehicle', table_name: 'vehicles', validators: [:name],
                                column_names: %w[id type name settings])
        car = mock_ar_class(name: 'Car', table_name: 'vehicles', superclass: vehicle,
                            validators: [:name], stored_attrs: { settings: [:color, :theme] })
        allow(vehicle).to receive(:descendants).and_return([car])

        cols = [id_col, type_col, name_col, settings_col]
        result = described_class.partition(vehicle, cols)

        car_group = result.find { |label, _| label == 'Car columns' }
        expect(car_group).not_to be_nil
        expect(car_group[1].map { |c| c.name }).to eq ['settings']
      end

      it 'includes multi-level descendants via descendants' do
        vehicle = mock_ar_class(name: 'Vehicle', table_name: 'vehicles', validators: [:name],
                                column_names: %w[id type name num_doors battery_kwh])
        car = mock_ar_class(name: 'Car', table_name: 'vehicles', superclass: vehicle,
                            validators: [:name, :num_doors])
        electric_car = mock_ar_class(name: 'ElectricCar', table_name: 'vehicles', superclass: car,
                                     validators: [:name, :num_doors, :battery_kwh])
        # descendants returns all levels, subclasses returns only direct
        allow(vehicle).to receive(:descendants).and_return([car, electric_car])
        allow(car).to receive(:descendants).and_return([electric_car])

        cols = [id_col, type_col, name_col, num_doors_col, battery_col]
        result = described_class.partition(vehicle, cols)

        labels = result.map(&:first)
        expect(labels).to include('Vehicle columns', 'Car columns', 'ElectricCar columns')

        electric_group = result.find { |label, _| label == 'ElectricCar columns' }
        expect(electric_group[1].map { |c| c.name }).to eq ['battery_kwh']
      end
    end
  end
end
