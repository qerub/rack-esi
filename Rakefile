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
