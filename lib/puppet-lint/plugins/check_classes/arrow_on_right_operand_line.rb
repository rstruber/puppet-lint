# Public: Test the manifest tokens for chaining arrow that is
# on the line of the left operand when the right operand is on another line.
#
# https://docs.puppet.com/guides/style_guide.html#chaining-arrow-syntax
PuppetLint.new_check(:arrow_on_right_operand_line) do
  def check
    tokens.select { |r| Set[:IN_EDGE, :IN_EDGE_SUB].include?(r.type) }.each do |token|
      if token.next_code_token.line != token.line
        notify :warning, {
          :message =>  'arrow should be on the right operand\'s line',
          :line    => token.line,
          :column  => token.column,
          :token   => token,
        }
      end
    end
  end

  def fix(problem)
    token = problem[:token]

    prev_code_token = token.prev_code_token
    next_code_token = token.next_code_token
    indent_token = prev_code_token.prev_token_of(:INDENT)

    # Delete all tokens between the two code tokens the anchor is between
    temp_token = prev_code_token
    while (temp_token = temp_token.next_token) and (temp_token != next_code_token)
      tokens.delete(temp_token) unless temp_token == token
    end

    # Insert a newline and an indent before the arrow
    index = tokens.index(token)
    newline_token = PuppetLint::Lexer::Token.new(:NEWLINE, "\n", token.line, 0)
    tokens.insert(index, newline_token)
    if indent_token
      tokens.insert(index + 1, indent_token)
    end

    # Insert a space between the arrow and the following code token
    index = tokens.index(token)
    whitespace_token = PuppetLint::Lexer::Token.new(:WHITESPACE, ' ', token.line, 3)
    whitespace_token.prev_token = token
    token.next_token = whitespace_token
    whitespace_token.next_token = token.next_code_token
    token.next_code_token.prev_token = whitespace_token
    tokens.insert(index + 1, whitespace_token)
  end
end
