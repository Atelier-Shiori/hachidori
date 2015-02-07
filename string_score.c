
/*!
 * string_score.c: String Scoring Algorithm 0.1
 * https://github.com/kurige/string_score
 *
 * Based on Javascript code by Joshaven Potter
 * https://github.com/joshaven/string_score
 *
 * MIT license: http://www.opensource.org/licenses/mit-license.php
 *
 * Date: Tue Mar 21 2011
*/

#include <ctype.h>
#include <string.h>

#define ACRONYM_BONUS       0.8
#define CONSECUTIVE_BONUS   0.6
#define START_OF_STR_BONUS  0.1
#define SAMECASE_BONUS      0.1
#define MATCH_BONUS         0.1

double string_score_impl( const char* a, const char* b, double fuzziness );
double string_fuzzy_score( const char* a, const char* b, double fuzziness );

double string_score( const char* a, const char* b )
{
    return string_fuzzy_score( a, b, 0.0 );
}

double string_fuzzy_score( const char* a, const char* b, double fuzziness )
{
    return string_score_impl( a, b, fuzziness );
}

double string_score_impl( const char* a, const char* b, double fuzziness )
{
    /* If the original string is equal to the abbreviation, perfect match. */
    if( strcmp( a, b ) == 0 ) return 1.0;
    /* If the comparison string is empty, perfectly bad match. */
    if( strlen(b) == 0 ) return 0.0;
    
    size_t a_len = strlen(a);
    size_t b_len = strlen(b);
    
    /* Create a copy of original string, so that we can manipulate it. */
    const char* aptr = a;
    
    double score = 0.0;
    int start_of_string_bonus = 0;
    
    int c;
    size_t c_index;
    char c_cases[] = "  ";
    
    double fuzzies = 1.0;
    
    /* Walk through abbreviation and add up scores. */
    size_t i;
    for( i = 0; i < b_len; ++i )
    {
        /* Find the first case-insensitive match of a character. */
        c = b[i];
        //printf( "- %c (%s)\n", c, aptr );
        c_cases[0] = (char)toupper(c);
        c_cases[1] = (char)tolower(c);
        c_index = strcspn( aptr, c_cases );
        
        /* Set base score for any matching char. */
        if( c_index == strlen(aptr) )
        {
            if( fuzziness > 0.0 )
            {
                fuzzies += 1.0 - fuzziness;
                continue;
            }
            return 0.0;
        }
        else
            score += MATCH_BONUS;
        
        /* Same-case bonus. */
        if( aptr[c_index] == c )
        {
            //printf( "* Same case bonus.\n" );
            score += SAMECASE_BONUS;
        }
        
        /* Consecutive letter & start-of-string bonus. */
        if( c_index == 0 )
        {
            /* Increase the score when matching first character of the
               remainder of the string. */
            //printf( "* Consecutive char bonus.\n" );
            score += CONSECUTIVE_BONUS;
            if( i == 0 )
                /* If match is the first char of the string & the first char
                   of abbreviation, add a start-of-string match bonus. */
                start_of_string_bonus = 1;
        }
        else if( aptr[c_index - 1] == ' ' )
        {
            /* Acronym Bonus
             * Weighing Logic: Typing the first character of an acronym is as
             * if you preceded it with two perfect character matches. */
            //printf( "* Acronym bonus.\n" );
            score += ACRONYM_BONUS;
        }
        
        /* Left trim the already matched part of the string.
           (Forces sequential matching.) */
        aptr += c_index + 1;
    }
    
    score /= (double)b_len;
    
    /* Reduce penalty for longer strings. */
    score = ((score * (b_len / (double)a_len)) + score) / 2;
    score /= fuzzies;
    
    if( start_of_string_bonus && (score + START_OF_STR_BONUS < 1) )
    {
        //printf( "* Start of string bonus.\n" );
        score += START_OF_STR_BONUS;
    }
    
    return score;
}
