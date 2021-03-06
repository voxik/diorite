/*
 * Copyright 2016 Jiří Janoušek <janousek.jiri@gmail.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met: 
 * 
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer. 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution. 
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

namespace Diorite.String
{
/**
 * Check whether string is empty, i.e. `null` or `""`.
 * 
 * @param str    string to test
 * @return true if string is empty, false otherwise
 */
public inline bool is_empty(string? str)
{
	return str == null || str[0] == '\0';
}

/**
 * Ensure string is not empty but either non-empty or null
 * 
 * @param str    original string
 * @return original string if it isn't empty, null otherwise	
 */
public inline string? null_if_empty(string? str)
{
	return (str == null || str[0] == '\0') ? null : str;
}

/**	
 * Splits a string into a maximum of `max_tokens` pieces, using the given `delimiter` and ignoring
 * empty elements after stripping.
 * 
 * If `max_tokens` is reached, the remainder of string is appended to the last token.
 * 
 * @param data          a string to split
 * @param delimiter     a string which specifies the places at which to split the string. The delimiter is not
 *                      included in any of the resulting strings, unless `max_tokens` is reached.
 * @param max_tokens    the maximum number of pieces to split string into. If this is less than 1, the string 
 *                      is split completely.
 * @return resulting list of strings
 */
public SList<string> split_strip(string? data, string delimiter, int max_tokens=0)
{
	if (is_empty(data))
		return new SList<string>();
	return array_to_slist(data.split(delimiter, max_tokens), true);
}


/**
 * Creates list from array of strings
 * 
 * @param array    string array
 * @param strip    strip array elements and ignore empty elements
 * @return resulting list of strings
 */
public SList<string> array_to_slist(string[] array, bool strip=false)
{
	SList<string> result = null;
	foreach (unowned string item in array)
	{
		if (!strip)
		{
			result.prepend(item);
		}
		else if (!is_empty(item))
		{
			var stripped_item = item.strip();
			if (!is_empty(stripped_item))
				result.prepend((owned) stripped_item);
		}
	}
	result.reverse();
	return (owned) result;
}


	
public int index_of_char(string str, unichar c, int start_index = 0, ssize_t len = -1)
{
	char* result = g_utf8_strchr((char*) str + start_index, len, c);
	return result != null ? (int) (result - (char*) str) : -1;
}

public int last_index_of_char(string str, unichar c, int start_index = 0, ssize_t len = -1)
{
	char* result = g_utf8_strrchr((char*) str + start_index, len, c);
	return result != null ? (int) (result - (char*) str) : -1;
}

public string? unmask(uint8[] data)
{
	var length = data.length;
	if (length < 2)
		return null;
	var shift = data[0];
	var result = new uint8[length];
	for (var i = 1; i < length; i++)
	{
		if (shift > data[i])
			return null;
		result[i - 1] = data[i] - shift;
	}
	result[length] = 0;
	return (string) result;
}

} // namespace Diorite.String
