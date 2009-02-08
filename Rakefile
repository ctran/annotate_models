%w[rubygems rake rake/clean fileutils newgem rubigen].each { |f| require f }
require 'lib/annotate'

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.new('annotate', Annotate::VERSION) do |p|
  p.developer('Cuong Tran', 'ctran@pragmaquest.com')
  p.changes              = p.paragraphs_of("History.txt", 0..1).join("\n\n")
  p.rubyforge_name       = 'annotate-models'
  p.url                  = "http://github.com/ctran/annotate_models"
  p.summary              = "Annotates Rails Models, routes, and others"
  p.description          = "Annotates Rails Models, routes, and others"
  
  p.extra_dev_deps = [
    ['newgem', ">= #{::Newgem::VERSION}"]
  ]
  
  p.clean_globs |= %w[**/.DS_Store tmp *.log]
  path = (p.rubyforge_name == p.name) ? p.rubyforge_name : "\#{p.rubyforge_name}/\#{p.name}"
  p.remote_rdoc_dir = File.join(path.gsub(/^#{p.rubyforge_name}\/?/,''), 'rdoc')
  p.rsync_args = '-av --delete --ignore-errors'
end

require 'newgem/tasks'
Dir['tasks/**/*.rake'].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
# task :default => [:spec, :features]
