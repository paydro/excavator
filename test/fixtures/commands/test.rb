command :test do
  puts "test command"
end

desc "A command with an argument"
param :region, :default => "west"
command :command_with_arg do
  puts params[:region]
end

namespace :first do
  namespace :second do
    command :third do
      puts "third"
    end
  end
end

