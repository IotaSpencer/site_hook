##
#
# Copyright 2019 Ken Spencer / IotaSpencer
#
# 
# File: prompt_project.rb
# Created: 2/15/19
#
# License is in project root, MIT License is in use.
##

require 'highline'
require 'site_hook/prompt'
module SiteHook
  module Prompts
    class Project < ::SiteHook::Prompt
      runnable [:prompt_name, :prompt_src_path]
      @@hl = HighLine.new($stdin, $stdout, 0, 0, 0, 0)
      desc 'Prompts for project details'
      def prompt_name
        @@hl.say(<<~STATEMENT)
          What's the name of the project?
        STATEMENT
        @@hl.choose do |menu|
          menu.confirm   = 'Are you sure? '
          menu.select_by = :index_or_name
          menu.index     = '*'
          menu.prompt    = '> '
          menu.flow      = :rows
          menu.default   = Pathname.new(`pwd`).basename.to_s.chomp!
          menu.choice(Pathname.new(`pwd`).basename.to_s.chomp!) do |answer|
            @project_name = answer
          end
          menu.choice('Custom / Input your own?') do
            @project_name = @@hl.ask('> ', String) do |q|
              q.confirm = true
            end
          end
        end
      end
      def prompt_src_path
        @@hl.say(<<~STATEMENT)
        What's the src path?
        STATEMENT
      end
    end
  end
end