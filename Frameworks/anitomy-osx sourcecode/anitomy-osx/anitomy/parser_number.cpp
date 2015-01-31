/*
** Anitomy
** Copyright (C) 2014-2015, Eren Okka
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
#include <regex>

#include "element.h"
#include "keyword.h"
#include "parser.h"
#include "string2.h"

namespace anitomy {

void Parser::SetEpisodeNumber(string_t number, Token& token) {
  elements_.insert(kElementEpisodeNumber, number);
  token.category = kIdentifier;
}

////////////////////////////////////////////////////////////////////////////////

bool Parser::NumberComesAfterEpisodePrefix(Token& token) {
  size_t number_begin = FindNumberInString(token.content);
  auto prefix = keyword_manager.Normalize(token.content.substr(0, number_begin));

  if (keyword_manager.Find(kElementEpisodePrefix, prefix)) {
    auto number = token.content.substr(
        number_begin, token.content.length() - number_begin);
    if (!MatchEpisodePatterns(number, token))
      SetEpisodeNumber(number, token);
    return true;
  }

  return false;
}

bool Parser::NumberComesAfterEpisodeKeyword(const token_iterator_t& token) {
  auto previous_token = GetPreviousNonDelimiterToken(tokens_, token);

  if (previous_token != tokens_.end()) {
    if (previous_token->category == kUnknown) {
      auto keyword = keyword_manager.Normalize(previous_token->content);

      if (keyword_manager.Find(kElementEpisodePrefix, keyword)) {
        if (!MatchEpisodePatterns(token->content, *token))
          SetEpisodeNumber(token->content, *token);
        previous_token->category = kIdentifier;
        return true;
      }
    }
  }

  return false;
}

bool Parser::NumberComesBeforeTotalNumber(const token_iterator_t& token) {
  auto next_token = GetNextNonDelimiterToken(tokens_, token);

  if (next_token != tokens_.end()) {
    if (IsStringEqualTo(next_token->content, L"of")) {
      auto other_token = GetNextNonDelimiterToken(tokens_, next_token);

      if (other_token != tokens_.end()) {
        if (IsNumericString(other_token->content)) {
          SetEpisodeNumber(token->content, *token);
          next_token->category = kIdentifier;
          other_token->category = kIdentifier;
          return true;
        }
      }
    }
  }

  return false;
}

bool Parser::SearchForEpisodePatterns(std::vector<size_t>& tokens) {
  for (const auto& token_index : tokens) {
    auto token = tokens_.begin() + token_index;
    bool numeric_front = IsNumericChar(token->content.front());

    if (!numeric_front) {
      // e.g. "EP.01"
      if (NumberComesAfterEpisodePrefix(*token))
        return true;
    } else {
      // e.g. "Episode 01"
      if (NumberComesAfterEpisodeKeyword(token))
        return true;
      // e.g. "8 of 12"
      if (NumberComesBeforeTotalNumber(token))
        return true;
    }
    // Look for other patterns
    if (MatchEpisodePatterns(token->content, *token))
      return true;
  }

  return false;
}

////////////////////////////////////////////////////////////////////////////////

typedef std::basic_regex<char_t> regex_t;
typedef std::match_results<string_t::const_iterator> regex_match_results_t;

bool Parser::MatchSingleEpisodePattern(const string_t& word, Token& token) {
  static const regex_t pattern(L"(\\d{1,3})v(\\d)");
  regex_match_results_t match_results;

  if (std::regex_match(word, match_results, pattern)) {
    SetEpisodeNumber(match_results[1].str(), token);
    elements_.insert(kElementReleaseVersion, match_results[2].str());
    return true;
  }

  return false;
}

bool Parser::MatchMultiEpisodePattern(const string_t& word, Token& token) {
  static const regex_t pattern(L"(\\d{1,3})[-&+](\\d{1,3})(?:v(\\d))?");
  regex_match_results_t match_results;

  if (std::regex_match(word, match_results, pattern)) {
    auto lower_bound = match_results[1].str();
    auto upper_bound = match_results[2].str();
    // Avoid matching expressions such as "009-1" or "5-2"
    if (StringToInt(lower_bound) < StringToInt(upper_bound)) {
      SetEpisodeNumber(lower_bound, token);
      SetEpisodeNumber(upper_bound, token);
      if (match_results[3].matched)
        elements_.insert(kElementReleaseVersion, match_results[3].str());
      return true;
    }
  }

  return false;
}

bool Parser::MatchSeasonAndEpisodePattern(const string_t& word, Token& token) {
  static const regex_t pattern(L"S?"
                               L"(\\d{1,2})(?:-S?(\\d{1,2}))?"
                               L"(?:x|[ ._-x]?E)"
                               L"(\\d{1,3})(?:-E?(\\d{1,3}))?",
                               std::regex_constants::icase);
  regex_match_results_t match_results;

  if (std::regex_match(word, match_results, pattern)) {
    elements_.insert(kElementAnimeSeason, match_results[1]);
    if (match_results[2].matched)
      elements_.insert(kElementAnimeSeason, match_results[2]);
    SetEpisodeNumber(match_results[3], token);
    if (match_results[4].matched)
      SetEpisodeNumber(match_results[4], token);
    return true;
  }

  return false;
}

bool Parser::MatchTypeAndEpisodePattern(const string_t& word, Token& token) {
  if (!elements_.empty(kElementAnimeType))
    return false;

  static const regex_t pattern(L"(ED|NCED|NCOP|OP|OVA|PV)(\\d{1,2})[a-f]?");
  regex_match_results_t match_results;

  if (std::regex_match(word, match_results, pattern)) {
    elements_.insert(kElementAnimeType, match_results[1].str());
    SetEpisodeNumber(match_results[2].str(), token);
    return true;
  }

  return false;
}

bool Parser::MatchJapaneseCounterPattern(const string_t& word, Token& token) {
  if (word.back() != L'\u8A71')
    return false;

  static const regex_t pattern(L"(\\d{1,3})\u8A71");
  regex_match_results_t match_results;

  if (std::regex_match(word, match_results, pattern)) {
    SetEpisodeNumber(match_results[1].str(), token);
    return true;
  }

  return false;
}

bool Parser::MatchEpisodePatterns(string_t word, Token& token) {
  // All patterns contain at least one non-numeric character
  if (IsNumericString(word))
    return false;

  TrimString(word, L" -");

  const bool numeric_front = IsNumericChar(word.front());
  const bool numeric_back = IsNumericChar(word.back());

  // e.g. "01v2"
  if (numeric_front && numeric_back)
    if (MatchSingleEpisodePattern(word, token))
      return true;
  // e.g. "01-02", "03-05v2"
  if (numeric_front && numeric_back)
    if (MatchMultiEpisodePattern(word, token))
      return true;
  // e.g. "2x01", "S01E03", "S01-02xE001-150"
  if (numeric_back)
    if (MatchSeasonAndEpisodePattern(word, token))
      return true;
  // e.g. "ED1", "OP4a", "OVA2"
  if (!numeric_front)
    if (MatchTypeAndEpisodePattern(word, token))
      return true;
  // U+8A71 is used as counter for stories, episodes of TV series, etc.
  if (numeric_front)
    if (MatchJapaneseCounterPattern(word, token))
      return true;

  return false;
}

////////////////////////////////////////////////////////////////////////////////

bool Parser::SearchForIsolatedNumbers(std::vector<size_t>& tokens) {
  auto is_bracket_token = [&](token_iterator_t token) {
    return token != tokens_.end() && token->category == kBracket;
  };

  for (auto token_index = tokens.begin();
       token_index != tokens.end(); ++token_index) {
    auto token = tokens_.begin() + *token_index;
    
    auto previous_token = GetPreviousNonDelimiterToken(tokens_, token);
    if (!is_bracket_token(previous_token))
      continue;
    auto next_token = GetNextNonDelimiterToken(tokens_, token);
    if (!is_bracket_token(next_token))
      continue;

    auto number = StringToInt(token->content);
    // While there are about a dozen anime series with more than 1000
    // episodes (e.g. Doraemon), it's safe to assume that any number above
    // this line is not the episode number.
    if (number <= 1900) {
      SetEpisodeNumber(token->content, *token);
      return true;
    }
  }

  return false;
}

bool Parser::SearchForSeparatedNumbers(std::vector<size_t>& tokens) {
  for (auto token_index = tokens.begin();
       token_index != tokens.end(); ++token_index) {
    auto token = tokens_.begin() + *token_index;
    auto previous_token = GetPreviousNonDelimiterToken(tokens_, token);

    // See if the number has a preceding "-" separator
    if (previous_token != tokens_.end() &&
        previous_token->category == kUnknown &&
        IsDashCharacter(previous_token->content)) {
      SetEpisodeNumber(token->content, *token);
      previous_token->category = kIdentifier;
      return true;
    }
  }

  return false;
}

bool Parser::SearchForLastNumber(std::vector<size_t>& tokens) {
  for (auto it = tokens.rbegin(); it != tokens.rend(); ++it) {
    size_t token_index = *it;
    auto token = tokens_.begin() + token_index;

    // Assuming that episode number always comes after the title, first token
    // cannot be what we're looking for
    if (token_index == 0)
      continue;

    // An enclosed token is unlikely to be the episode number at this point
    if (token->enclosed)
      continue;

    // Ignore if it's the first non-enclosed token
    if (std::all_of(tokens_.begin(), tokens_.begin() + token_index,
            [](const Token& token) { return token.enclosed; }))
      continue;

    // Check if the previous token is "Movie"
    auto previous_token = GetPreviousNonDelimiterToken(tokens_, token);
    if (previous_token != tokens_.end() &&
        previous_token->category == kUnknown &&
        IsStringEqualTo(previous_token->content, L"Movie")) {
      elements_.insert(kElementAnimeType, previous_token->content);
      continue;
    }

    // We'll use this number after all
    SetEpisodeNumber(token->content, *token);
    return true;
  }

  return false;
}

}  // namespace anitomy