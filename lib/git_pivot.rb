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

module GitPivot
  class GitPivot

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

      puts Table(:data => data, :column_names => ["ID", "Type", "Owner", "State", "Name"])
    end

  end
end
