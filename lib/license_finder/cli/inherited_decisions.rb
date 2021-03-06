# frozen_string_literal: true

module LicenseFinder
  module CLI
    class InheritedDecisions < Base
      extend Subcommand
      include MakesDecisions

      desc 'list', 'List all the inherited decision files'
      def list
        say 'Inherited Decision Files:', :blue
        say_each(decisions.inherited_decisions)
      end

      auditable
      desc 'add DECISION_FILE...', 'Add one or more decision files to the inherited decisions'
      def add(*decision_files)
        assert_some decision_files
        modifying { decision_files.each { |filepath| decisions.inherit_from(filepath) } }
        say "Added #{decision_files.join(', ')} to the inherited decisions"
      end

      auditable
      desc 'remove DECISION_FILE...', 'Remove one or more decision files from the inherited decisions'
      def remove(*decision_files)
        assert_some decision_files
        modifying { decision_files.each { |filepath| decisions.remove_inheritance(filepath) } }
        say "Removed #{decision_files.join(', ')} from the inherited decisions"
      end
    end
  end
end
