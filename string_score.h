#ifndef STRING_SCORE_H
#define STRING_SCORE_H

/*
   Generate a score between 0.0 and 1.0 representing the similarity between
   string `a` and string `b`.
   
   Limitations:
   * Both `a` and `b` must be null terminated strings.
   * To maintain my sanity only ASCII characters are currently supported.
 */

double string_score( const char* a, const char* b );

/*
   Same as above, but allow for "fuzzy" matches.
 */

double string_fuzzy_score( const char* a, const char* b, double fuzziness );

#endif /* STRING_SCORE_H */
