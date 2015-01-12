/*
** Anitomy
** Copyright (C) 2014, Eren Okka
** 
** This program is free software: you can redistribute it and/or modify
** it under the terms of the GNU General Public License as published by
** the Free Software Foundation, either version 3 of the License, or
** (at your option) any later version.
** 
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
** 
** You should have received a copy of the GNU General Public License
** along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <algorithm>
#include <set>

#include "string2.h"
#include "tokenizer.h"

namespace anitomy {

Tokenizer::Tokenizer(const string_t& filename, token_container_t& tokens)
    : filename_(filename),
      tokens_(tokens) {
}

bool Tokenizer::Tokenize() {
  tokens_.reserve(32);  // Usually there are no more than 20 tokens

  TokenizeByBrackets();

  return !tokens_.empty();
}

////////////////////////////////////////////////////////////////////////////////

void Tokenizer::AddToken(TokenCategory category, bool enclosed,
                         const TokenRange& range) {
  tokens_.push_back(Token(category,
                          filename_.substr(range.offset, range.size),
                          enclosed));
}

void Tokenizer::TokenizeByBrackets() {
  static const std::vector<std::pair<char_t, char_t>> brackets{
      {L'(', L')'},  // U+0028-U+0029 Parenthesis
      {L'[', L']'},  // U+005B-U+005D Square bracket
      {L'{', L'}'},  // U+007B-U+007D Curly bracket
      {L'\u300C', L'\u300D'},  // Corner bracket
      {L'\u300E', L'\u300F'},  // White corner bracket
      {L'\u3010', L'\u3011'},  // Black lenticular bracket
      {L'\uFF08', L'\uFF09'},  // Fullwidth parenthesis
  };

  bool is_bracket_open = false;
  char_t matching_bracket = L'\0';

  auto char_begin = filename_.begin();
  const auto char_end = filename_.end();

  // This is basically std::find_first_of() customized to our needs
  auto find_first_bracket = [&]() -> string_t::const_iterator {
    for (auto it = char_begin; it != char_end; ++it) {
      for (const auto& bracket_pair : brackets) {
        if (*it == bracket_pair.first) {
          matching_bracket = bracket_pair.second;
          return it;
        }
      }
    }
    return char_end;
  };

  auto current_char = char_begin;

  while (current_char != char_end && char_begin != char_end) {
    if (!is_bracket_open) {
      current_char = find_first_bracket();
    } else {
      // Looking for the matching bracket allows us to better handle some rare
      // cases with nested brackets.
      current_char = std::find(char_begin, char_end, matching_bracket);
    }

    const TokenRange range(std::distance(filename_.begin(), char_begin),
                           std::distance(char_begin, current_char));

    if (range.size > 0)  // Found unknown token
      TokenizeByDelimiters(is_bracket_open, range);

    if (current_char != char_end) {  // Found bracket
      AddToken(kBracket, true, TokenRange(range.offset + range.size, 1));
      is_bracket_open = !is_bracket_open;
      char_begin = ++current_char;
    }
  }
}

void Tokenizer::TokenizeByDelimiters(bool enclosed, const TokenRange& range) {
  // Each group occasionally has different delimiters, which is why we can't
  // analyze the whole filename in one go.
  string_t delimiters = GetDelimiters(range);

  if (delimiters.empty()) {
    AddToken(kUnknown, enclosed, range);
    return;
  }

  auto char_begin = filename_.begin() + range.offset;
  const auto char_end = char_begin + range.size;
  auto current_char = char_begin;

  while (current_char != char_end) {
    current_char = std::find_first_of(current_char, char_end,
                                      delimiters.begin(), delimiters.end());

    const TokenRange sub_range(std::distance(filename_.begin(), char_begin),
                               std::distance(char_begin, current_char));

    if (sub_range.size > 0)  // Found unknown token
      AddToken(kUnknown, enclosed, sub_range);

    if (current_char != char_end) {  // Found delimiter
      AddToken(kDelimiter, enclosed,
               TokenRange(sub_range.offset + sub_range.size, 1));
      char_begin = ++current_char;
    }
  }

  ValidateDelimiterTokens();
}

////////////////////////////////////////////////////////////////////////////////

string_t Tokenizer::GetDelimiters(const TokenRange& range) const {
  static const string_t kValidDelimiters = L" &+,._|";

  std::set<char_t> delimiters;
  for (size_t i = range.offset; i < range.offset + range.size; i++) {
    const char_t character = filename_.at(i);
    if (!IsAlphanumericChar(character))
      if (kValidDelimiters.find(character) != kValidDelimiters.npos)
        delimiters.insert(character);
  }

  string_t output;
  for (const auto& delimiter : delimiters)
    output.push_back(delimiter);
  return output;
}

void Tokenizer::ValidateDelimiterTokens() {
  auto get_previous_valid_token = [&](token_iterator_t it) {
    if (it == tokens_.begin())
      return tokens_.end();
    do {
      --it;
    } while (it != tokens_.begin() && it->content.empty());
    return it;
  };
  auto get_next_valid_token = [&](token_iterator_t it) {
    do {
      ++it;
    } while (it != tokens_.end() && it->content.empty());
    return it;
  };

  for (auto token = tokens_.begin(); token != tokens_.end(); ++token) {
    if (token == tokens_.begin())
      continue;

    auto prev_token = get_previous_valid_token(token);
    auto next_token = get_next_valid_token(token);

    // Checking for single-character tokens prevents splitting group names,
    // keywords and the episode number in some cases.
    if (token->category == kDelimiter && token->content == L".") {
      if (prev_token->category == kUnknown &&
          prev_token->content.size() == 1) {
        prev_token->content.append(token->content);
        token->content.clear();
        if (next_token != tokens_.end() &&
            next_token->category == kUnknown) {
          prev_token->content.append(next_token->content);
          next_token->content.clear();
          continue;
        }
      }
      if (next_token != tokens_.end() &&
          next_token->category == kUnknown &&
          next_token->content.size() == 1) {
        prev_token->content.append(token->content);
        token->content.clear();
        prev_token->content.append(next_token->content);
        next_token->content.clear();
      }
    }
  }

  // Remove empty tokens
  for (size_t i = 0; i < tokens_.size(); ++i) {
    if (tokens_.at(i).content.empty()) {
      tokens_.erase(tokens_.begin() + i--);
    }
  }
}

}  // namespace anitomy