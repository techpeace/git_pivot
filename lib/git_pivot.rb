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

require 'ruport'
require 'pivotal-tracker'
require 'mutter'

module GitPivot
  class GitPivot
    
    module Styles
      STYLES = {
        :header  => {                     # an alias you can use anywhere in mutter
          :match => '*',
          :style => ['yellow', 'bold']    # these styles will be applied to the match
        }
      }
    end
    include Styles
    
    FORMATTER = Mutter.new(STYLES)

    # ssl should default to yes since http basic auth is insecure
    def initialize(project_id, token, owner, use_ssl = true)
      @owner = owner
      @tracker = PivotalTracker.new(project_id, token, {:use_ssl => use_ssl })
    end

    # list stories in current sprint
    def current_sprint
      iteration = @tracker.current_iteration
      display_stories(iteration.stories)
    end

    def my_work
      stories = @tracker.find({:owner => @owner, :state => "unstarted,started,finished,delivered,rejected"})
      display_stories(stories)
    end

    # display the full story
    def display_story(id)
      story = @tracker.find_story(id)
      notes = @tracker.notes(id)
      data = [:id, :name, :current_state, :estimate, :iteration, :story_type, :labels, :owned_by, :requested_by, :created_at, :accepted_at, :url].collect do |element_name|
        element = story.send(element_name)
        [element_name.to_s, element.to_s]
      end

      puts Table(:data => data, :column_names => ["Element", "Value"])
      puts "description:"
      puts story.description
      puts
      notes.each do |note|
        puts "#{note.noted_at} - #{note.author}"
        puts note.text
        puts
      end
    end

    # start story
    def start_story(id)
      story = @tracker.find_story(id)
      story.current_state = "started"
      @tracker.update_story(story)

      display_story(id)
    end

    # finish story
    def finish_story(id)
      story = @tracker.find_story(id)
      if story.story_type == "feature" or story.story_type == "bug"
        story.current_state = "finished"
      elsif story.story_type == "chore"
        story.current_state = "accepted"
      end
      @tracker.update_story(story)

      display_story(id)
    end

    private
    def display_stories(stories)
      data = stories.collect do |story| 
        [story.id, story.story_type, story.owned_by, story.current_state, story.name]
      end
      
      table = Table(:data => data, :column_names => %w{ID Type Owner State Name}).to_s
      puts format_table(table)
    end

    def format_table(table)
      formatted_table = ""
      
      formatted_splitter = FORMATTER['|', :red, :inverse]
      
      table.each_with_index do |line, index|
        # HEADER ROW
        if index == 1
          columns = line.split('|')
          formatted_table << columns.collect{ |col| FORMATTER[col, :cyan, :inverse] }.join(FORMATTER['|', :cyan, :inverse])
        elsif index == 0 || index == 2
          formatted_table << FORMATTER[line, :cyan, :inverse]
        elsif index > 2
          columns = line.split('|')
          
          state_col = columns[4] || ""
          state_color = case state_col.strip
                        when 'accepted'
                          :green
                        when 'rejected'
                          :red
                        when 'started'
                          :cyan
                        when 'delivered'
                          :yellow
                        else
                          :white
                        end
          
          index = -1
          formatted_cells = columns.collect do |col| 
            index += 1
            # STATE COLUMN
            if index == 4
              FORMATTER[col, state_color, :inverse]
            else
              FORMATTER[col, :white, :inverse]
            end
          end
          formatted_table << formatted_cells.join(formatted_splitter)
        end
      end
      
      formatted_table
    end
  end
end
