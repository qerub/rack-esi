namespace("tasks") do
  desc("Show TODOs")
  task("todo") do
    system("ack TODO:")
  end

  desc("Show FIXMEs")
  task("fixme") do
    system("ack FIXME:")
  end
end

desc("Show TODOs and FIXMEs")
task("tasks" => ["tasks:todo", "tasks:fixme"])

require "rake/testtask"

Rake::TestTask.new do |t|
  t.test_files = FileList["test/test*.rb"]
  t.verbose = true
end

desc("Update AUTHORS.txt")
task("update_authors") do
  system("git log | grep '^Author:' | sed 's/ <.*//; s/^Author: //' | sort | uniq -c | sort -nr | sed -E 's/^ *[0-9]+ //' > AUTHORS.txt")
end
