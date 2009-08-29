=begin
  Copyright (c) 2009 Terence Lee.

  This file is part of GitPivot

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

require 'trollop'
require 'date'

module GitPivot
  class Runner
    SUB_COMMANDS = %w{current}
    
    def initialize(args)
      @argv = args

      # configuration stuff
      configuration = YAML.load_file("git_pivot.yml")

      @git_pivot = GitPivot.new(configuration["project_id"], configuration["token"], configuration["owner"])
    end

    def run
      global_opts = Trollop::options do
        banner "A command-line interface to Pivotal Tracker."
        stop_on SUB_COMMANDS
      end
      
      cmd = @argv.shift # get the subcommand
      cmd_opts = case cmd
                 when "current" # parse delete options
                   @git_pivot.current_sprint
                 else
                   Trollop::die "unknown subcommand #{cmd.inspect}"
                 end
    end
  end
end
