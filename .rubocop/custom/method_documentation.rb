# encoding: utf-8

module RuboCop

  module Cop

    module Style

      # This cop checks for missing method-level documentation.
      class MethodDocumentation < Cop
        include AnnotationComment

        MSG = "Missing method-level documentation comment."

        # Public: Investigate the source for undocumented methods.
        def investigate(processed_source)
          ast = processed_source.ast
          return unless ast

          ast_with_comments = Parser::Source::Comment.associate(
            ast,
            processed_source.comments
          )

          check(ast, ast_with_comments)
        end

        private

        # Internal: Ensure that documentation is required for all methods. Adds
        # an offense when undocumented methods are detected.
        #
        # Returns nothing.
        def check(ast, ast_with_comments)
          ast.each_node(:def) do |node|
            _name, body = *node

            next if associated_comment?(node, ast_with_comments)
            add_offense(node, :keyword, MSG)
          end
        end

        # Internal: Does the node have a non-annotation comment on the preceding
        # line?
        #
        # Returns a Boolean.
        def associated_comment?(node, ast_with_comments)
          return false if ast_with_comments[node].empty?

          preceding_comment = ast_with_comments[node].last
          distance = node.loc.keyword.line - preceding_comment.loc.line
          return false if distance > 1

          # As long as there's at least one comment line that isn't an
          # annotation, it's OK.
          ast_with_comments[node].any? { |comment| !annotation?(comment) }
        end

      end

    end

  end

end
