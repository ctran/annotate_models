Colons can be used to align columns.

| Tables        | Are           | Cool  |
| ------------- |:-------------:| -----:|
| col 3 is      | right-aligned | $1600 |
| col 2 is      | centered      |   $12 |
| zebra stripes | are neat      |    $1 |

There must be at least 3 dashes separating each header cell.
The outer pipes (|) are optional, and you don't need to make the
raw Markdown line up prettily. You can also use inline Markdown.

Markdown | Less | Pretty
--- | --- | ---
*Still* | `renders` | **nicely**
1 | 2 | 3


 ## Route Map

  Prefix    | Verb       | URI Pattern     | Controller#Action    
  --------- | ---------- | --------------- | --------------------
  myaction1 | GET        | /url1(.:format) | mycontroller1#action
  myaction2 | POST       | /url2(.:format) | mycontroller2#action
  myaction3 | DELETE-GET | /url3(.:format) | mycontroller3#action \n")



 Table name: `users`

 ### Columns

 Name                    | Type               | Attributes
 ----------------------- | ------------------ | ---------------------------
 **`id`**                | `integer`          | `not null, primary key`
 **`foreign_thing_id`**  | `integer`          | `not null`

 ### Foreign Keys

 * `fk_rails_...` (_ON DELETE => on_delete_value ON UPDATE => on_update_value_):
     * **`foreign_thing_id => foreign_things.id`**
