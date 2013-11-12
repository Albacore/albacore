# Folder: `tasks`

The `tasks` folder contains modules and classes that extend the current Rakefile
with tasks. Files should be named after the tasks they 'create'.

For example, in a Rakefile, you can write:

``` ruby
Albacore::Tasks::Versionizer.new :versioning
```

to create a new task, named `:versioning` that you can then depend on from other
tasks.

It should be possible to call `.new` multiple times with different symbols as
parameters and you can also pass blocks to the task configurators that are
configurable.

