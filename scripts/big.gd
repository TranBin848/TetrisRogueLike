class_name Big
extends RefCounted












var mantissa: float

var exponent: int


const suffixes_metric_symbol: Dictionary = {
	"0": "", 
	"1": "K", 
	"2": "M", 
	"3": "B", 
	"4": "T", 
	"5": "Qa", 
	"6": "Qi", 
	"7": "Sx", 
	"8": "Sp", 
	"9": "Oc", 
	"10": "No", 
	"11": "Dc", 
	"12": "Ud", 
	"13": "Dd", 
	"14": "Td", 
	"15": "Qad", 
	"16": "Qid", 
	"17": "Sxd", 
	"18": "Spd", 
	"19": "Ocd", 
	"20": "Nod", 
	"21": "V", 
	"22": "Uv", 
	"23": "Dv", 
	"24": "Tv", 
	"25": "Qav", 
	"26": "Qiv", 
	"27": "Sxv", 
	"28": "Spv", 
	"29": "Ocv", 
	"30": "Nov", 
	"31": "Tg", 
}

const suffixes_metric_name: Dictionary = {
	"0": "", 
	"1": "kilo", 
	"2": "mega", 
	"3": "giga", 
	"4": "tera", 
	"5": "peta", 
	"6": "exa", 
	"7": "zetta", 
	"8": "yotta", 
	"9": "ronna", 
	"10": "quetta", 
}


static var suffixes_aa: Dictionary = {
	"0": "", 
	"1": "k", 
	"2": "m", 
	"3": "b", 
	"4": "t", 
	"5": "aa", 
	"6": "ab", 
	"7": "ac", 
	"8": "ad", 
	"9": "ae", 
	"10": "af", 
	"11": "ag", 
	"12": "ah", 
	"13": "ai", 
	"14": "aj", 
	"15": "ak", 
	"16": "al", 
	"17": "am", 
	"18": "an", 
	"19": "ao", 
	"20": "ap", 
	"21": "aq", 
	"22": "ar", 
	"23": "as", 
	"24": "at", 
	"25": "au", 
	"26": "av", 
	"27": "aw", 
	"28": "ax", 
	"29": "ay", 
	"30": "az", 
	"31": "ba", 
	"32": "bb", 
	"33": "bc", 
	"34": "bd", 
	"35": "be", 
	"36": "bf", 
	"37": "bg", 
	"38": "bh", 
	"39": "bi", 
	"40": "bj", 
	"41": "bk", 
	"42": "bl", 
	"43": "bm", 
	"44": "bn", 
	"45": "bo", 
	"46": "bp", 
	"47": "bq", 
	"48": "br", 
	"49": "bs", 
	"50": "bt", 
	"51": "bu", 
	"52": "bv", 
	"53": "bw", 
	"54": "bx", 
	"55": "by", 
	"56": "bz", 
	"57": "ca"
}


const alphabet_aa: Array[String] = [
	"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", 
	"n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"
]


const latin_ones: Array[String] = [
	"", "un", "duo", "tre", "quattuor", "quin", "sex", "septen", "octo", "novem"
]

const latin_tens: Array[String] = [
	"", "dec", "vigin", "trigin", "quadragin", "quinquagin", "sexagin", "septuagin", "octogin", "nonagin"
]

const latin_hundreds: Array[String] = [
	"", "cen", "duocen", "trecen", "quadringen", "quingen", "sescen", "septingen", "octingen", "nongen"
]

const latin_special: Array[String] = [
	"", "mi", "bi", "tri", "quadri", "quin", "sex", "sept", "oct", "non"
]


static var options = {
	"default_mantissa": 1.0, 
	"default_exponent": 0, 
	"dynamic_decimals": false, 
	"dynamic_numbers": 4, 
	"small_decimals": 2, 
	"thousand_decimals": 2, 
	"big_decimals": 2, 
	"scientific_decimals": 2, 
	"logarithmic_decimals": 2, 
	"maximum_trailing_zeroes": 3, 
	"thousand_separator": ",", 
	"decimal_separator": ".", 
	"suffix_separator": "", 
	"reading_separator": "", 
	"thousand_name": "thousand"
}


const MANTISSA_MAX: float = 1209600.0

const MANTISSA_PRECISION: float = 1e-07


const INT_MIN: int = -9223372036854775808

const INT_MAX: int = 9223372036854775807

func _init(m: Variant = options["default_mantissa"], e: int = options["default_exponent"]) -> void :
	if m is Big:
		mantissa = m.mantissa
		exponent = m.exponent
	elif typeof(m) == TYPE_STRING:
		var scientific: PackedStringArray = m.split("e")
		mantissa = float(scientific[0])
		exponent = int(scientific[1]) if scientific.size() > 1 else 0
	else:
		if typeof(m) != TYPE_INT and typeof(m) != TYPE_FLOAT:
			printerr("Big Error: Unknown data type passed as a mantissa!")
		mantissa = m
		exponent = e
	Big._size_check(mantissa)
	Big.normalize(self)


static func _type_check(n) -> Big:
	if n is Big:
		return n
	var result: = Big.new(n)
	return result




static func _size_check(m: float) -> void :
	if m > MANTISSA_MAX:


		pass




static func normalize(big: Big) -> void :

	var is_negative: = false
	if big.mantissa < 0:
		is_negative = true
		big.mantissa *= -1

	big.mantissa = snapped(big.mantissa, MANTISSA_PRECISION)
	if big.mantissa < 1.0 or big.mantissa >= 10.0:
		var diff: int = floor(log10(big.mantissa))
		if diff > -10 and diff < 248:
			var div = 10.0 ** diff
			if div > MANTISSA_PRECISION:
				big.mantissa /= div
				big.exponent += diff
	while big.exponent < 0:
		big.mantissa *= 0.1
		big.exponent += 1
	while big.mantissa >= 10.0:
		big.mantissa *= 0.1
		big.exponent += 1
	if big.mantissa == 0:
		big.mantissa = 0.0
		big.exponent = 0
	big.mantissa = snapped(big.mantissa, MANTISSA_PRECISION)


	if (is_negative):
		big.mantissa *= -1



static func absolute(x) -> Big:
	var result: = Big.new(x)
	result.mantissa = abs(result.mantissa)
	return result



static func add(x, y) -> Big:
	x = Big._type_check(x)
	y = Big._type_check(y)
	var result: = Big.new(x)

	var exp_diff: float = y.exponent - x.exponent

	if exp_diff < 248.0:
		var scaled_mantissa: float = y.mantissa * 10 ** exp_diff
		result.mantissa = x.mantissa + scaled_mantissa
	elif x.is_less_than(y):
		result.mantissa = y.mantissa
		result.exponent = y.exponent
	Big.normalize(result)
	return result



static func subtract(x, y) -> Big:
	x = Big._type_check(x)
	y = Big._type_check(y)
	var negated_y: = Big.new( - y.mantissa, y.exponent)
	return add(negated_y, x)



static func times(x, y) -> Big:
	x = Big._type_check(x)
	y = Big._type_check(y)
	var result: = Big.new()

	var new_exponent: int = y.exponent + x.exponent
	var new_mantissa: float = y.mantissa * x.mantissa
	while new_mantissa >= 10.0:
		new_mantissa /= 10.0
		new_exponent += 1
	result.mantissa = new_mantissa
	result.exponent = new_exponent
	Big.normalize(result)
	return result



static func division(x, y) -> Big:
	x = Big._type_check(x)
	y = Big._type_check(y)
	var result: = Big.new(x)

	if y.mantissa > - MANTISSA_PRECISION and y.mantissa < MANTISSA_PRECISION:
		printerr("Big Error: Divide by zero or less than " + str(MANTISSA_PRECISION))
		return x
	var new_exponent = x.exponent - y.exponent
	var new_mantissa = x.mantissa / y.mantissa
	while new_mantissa > 0.0 and new_mantissa < 1.0:
		new_mantissa *= 10.0
		new_exponent -= 1
	result.mantissa = new_mantissa
	result.exponent = new_exponent
	Big.normalize(result)
	return result



static func powers(x: Big, y) -> Big:
	var result: = Big.new(x)
	if typeof(y) == TYPE_INT:
		if y <= 0:
			if y < 0:
				printerr("Big Error: Negative exponents are not supported!")
			result.mantissa = 1.0
			result.exponent = 0
			return result

		var y_mantissa: float = 1.0
		var y_exponent: int = 0

		while y > 1:
			Big.normalize(result)
			if y % 2 == 0:
				result.exponent *= 2
				result.mantissa **= 2
				y = y / 2
			else:
				y_mantissa = result.mantissa * y_mantissa
				y_exponent = result.exponent + y_exponent
				result.exponent *= 2
				result.mantissa **= 2
				y = (y - 1) / 2

		result.exponent = y_exponent + result.exponent
		result.mantissa = y_mantissa * result.mantissa
		Big.normalize(result)
		return result
	elif typeof(y) == TYPE_FLOAT:
		if result.mantissa == 0:
			return result


		var temp: float = result.exponent * y
		var new_mantissa = result.mantissa ** y
		if (round(y) == y
				and temp <= INT_MAX
				and temp >= INT_MIN
				and is_finite(temp)
		):
			if is_finite(new_mantissa):
				result.mantissa = new_mantissa
				result.exponent = int(temp)
				Big.normalize(result)
				return result


		var new_exponent: int = int(temp)
		var residue: float = temp - new_exponent
		new_mantissa = 10 ** (y * Big.log10(result.mantissa) + residue)
		if new_mantissa != INF and new_mantissa != - INF:
			result.mantissa = new_mantissa
			result.exponent = new_exponent
			Big.normalize(result)
			return result

		if round(y) != y:
			printerr("Big Error: Power function does not support large floats, use integers!")

		return powers(x, int(y))
	elif y is Big:

		if y.is_equal_to(0):
			return Big.new(1)
		if y.is_less_than(0):
			printerr("Big Error: Negative exponents are not supported!")
			return Big.new(0)

		var exponent_decremented: Big = y.minus(1)
		while exponent_decremented.is_greater_than(0):
			result.multiply_equals(x)
			exponent_decremented.minus_equals(1)

		return result
	else:
		printerr("Big Error: Unknown/unsupported data type passed as an exponent in power function!")
		return x



static func root(x: Big) -> Big:
	var result: = Big.new(x)

	if result.exponent % 2 == 0:
		result.mantissa = sqrt(result.mantissa)
		@warning_ignore("integer_division")
		result.exponent = result.exponent / 2
	else:
		result.mantissa = sqrt(result.mantissa * 10)
		@warning_ignore("integer_division")
		result.exponent = (result.exponent - 1) / 2
	Big.normalize(result)
	return result



static func modulo(x, y) -> Big:
	x = Big._type_check(x)
	y = Big._type_check(y)
	var result = x.divide(y)
	result = Big.round_down(result)
	result = Big.times(result, y)
	result = Big.subtract(x, result)
	return result



static func round_down(x: Big) -> Big:
	if x.exponent == 0:
		x.mantissa = floor(x.mantissa)
	else:
		var precision: = 1.0
		for i in range(min(8, x.exponent)):
			precision /= 10.0
		if precision < MANTISSA_PRECISION:
			precision = MANTISSA_PRECISION
		x.mantissa = floor(x.mantissa / precision) * precision
	return x

static func round_up(x: Big) -> Big:
	if x.exponent == 0:
		x.mantissa = ceil(x.mantissa)
	else:
		var precision: = 1.0
		for i in range(min(8, x.exponent)):
			precision /= 10.0
		if precision < MANTISSA_PRECISION:
			precision = MANTISSA_PRECISION
		x.mantissa = ceil(x.mantissa / precision) * precision
	return x


static func min_value(m, n) -> Big:
	m = Big._type_check(m)
	if m.is_less_than(n):
		return m
	else:
		return n



static func max_value(m, n) -> Big:
	m = Big._type_check(m)
	if m.is_greater_than(n):
		return m
	else:
		return n



func plus(n) -> Big:
	return Big.add(self, n)



func plus_equals(n) -> Big:
	var new_value = Big.add(self, n)
	mantissa = new_value.mantissa
	exponent = new_value.exponent
	return self



func minus(n) -> Big:
	return Big.subtract(self, n)



func minus_equals(n) -> Big:
	var new_value: Big = Big.subtract(self, n)
	mantissa = new_value.mantissa
	exponent = new_value.exponent
	return self



func multiply(n) -> Big:
	return Big.times(self, n)



func multiply_equals(n) -> Big:
	var new_value: Big = Big.times(self, n)
	mantissa = new_value.mantissa
	exponent = new_value.exponent
	return self



func divide(n) -> Big:
	return Big.division(self, n)



func divide_equals(n) -> Big:
	var new_value: Big = Big.division(self, n)
	mantissa = new_value.mantissa
	exponent = new_value.exponent
	return self



func mod(n) -> Big:
	return Big.modulo(self, n)



func mod_equals(n) -> Big:
	var new_value: = Big.modulo(self, n)
	mantissa = new_value.mantissa
	exponent = new_value.exponent
	return self



func power(n) -> Big:
	return Big.powers(self, n)



func power_equals(n) -> Big:
	var new_value: Big = Big.powers(self, n)
	mantissa = new_value.mantissa
	exponent = new_value.exponent
	return self



func square_root() -> Big:
	return Big.root(self)



func squared() -> Big:
	var new_value: = Big.root(self)
	mantissa = new_value.mantissa
	exponent = new_value.exponent
	return self



static func sort_increasing(a: Big, b: Big):
	if a.is_less_than(b):
		return true
	else:
		return false



static func sort_decreasing(a: Big, b: Big):
	if a.is_less_than(b):
		return false
	else:
		return true



func is_equal_to(n) -> bool:
	n = Big._type_check(n)
	Big.normalize(n)
	return n.exponent == exponent and is_equal_approx(n.mantissa, mantissa)



func is_greater_than(n) -> bool:
	return !is_less_than_or_equal_to(n)



func is_greater_than_or_equal_to(n) -> bool:
	return !is_less_than(n)



func is_less_than(n) -> bool:
	n = Big._type_check(n)
	Big.normalize(n)
	if (mantissa == 0
			and (n.mantissa > MANTISSA_PRECISION or mantissa < MANTISSA_PRECISION)
			and n.mantissa == 0
	):
		return false

	if mantissa < 0 and n.mantissa >= 0:
		return true
	elif mantissa >= 0 and n.mantissa < 0:
		return false

	var invert: bool = mantissa < 0 and n.mantissa < 0
	if invert:
		mantissa = mantissa * -1
		n.mantissa = n.mantissa * -1

	var result: bool

	if exponent < n.exponent:
		if exponent == n.exponent - 1 and mantissa > n.mantissa * 10:
			result = false
		else:
			result = true
	elif exponent == n.exponent:
		if mantissa < n.mantissa:
			result = true
		else:
			result = false
	else:
		if exponent == n.exponent + 1 and mantissa < n.mantissa / 10:
			result = true
		else:
			result = false

	if invert:
		mantissa = mantissa * -1
		n.mantissa = n.mantissa * -1
		return !result
	return result



func is_less_than_or_equal_to(n) -> bool:
	n = Big._type_check(n)
	Big.normalize(n)
	if is_less_than(n):
		return true
	if n.exponent == exponent and is_equal_approx(n.mantissa, mantissa):
		return true
	return false


static func log10(x) -> float:
	return log(x) * 0.4342944819032518


func abs_log10() -> float:
	return exponent + Big.log10(abs(mantissa))


func ln() -> float:
	return 2.302585092994045 * log_n(10)


func log_n(base) -> float:
	return (2.302585092994046 / log(base)) * (exponent + Big.log10(mantissa))


func pow10(value: int) -> void :
	mantissa = 10 ** (value % 1)
	exponent = int(value)


static func set_default_value(m: float, e: int) -> void :
	set_default_mantissa(m)
	set_default_exponent(e)


static func set_default_mantissa(value: float) -> void :
	options["default_mantissa"] = value


static func set_default_exponent(value: int) -> void :
	options["default_exponent"] = value


static func set_thousand_name(name: String) -> void :
	options.thousand_name = name



static func setThousandSeparator(separator: String) -> void :
	options.thousand_separator = separator



static func setDecimalSeparator(separator: String) -> void :
	options.decimal_separator = separator



static func setSuffixSeparator(separator: String) -> void :
	options.suffix_separator = separator



static func set_reading_separator(separator: String) -> void :
	options.reading_separator = separator



static func set_dynamic_decimals(d: bool) -> void :
	options.dynamic_decimals = d



static func set_dynamic_numbers(d: int) -> void :
	options.dynamic_numbers = d



static func set_maximum_trailing_zeroes(d: int) -> void :
	options.maximum_trailing_zeroes = d



static func setSmallDecimals(d: int) -> void :
	options.small_decimals = d



static func setThousandDecimals(d: int) -> void :
	options.thousand_decimals = d



static func setBigDecimals(d: int) -> void :
	options.big_decimals = d



static func setScientificDecimals(d: int) -> void :
	options.scientific_decimals = d



static func setLogarithmicDecimals(d: int) -> void :
	options.logarithmic_decimals = d



func _to_string() -> String:
	var mantissa_decimals: = 0
	if str(mantissa).find(".") >= 0:
		mantissa_decimals = str(mantissa).split(".")[1].length()
	if mantissa_decimals > exponent:
		if exponent < 248:
			return str(mantissa * 10 ** exponent)
		else:
			return to_plain_scientific()
	else:
		var mantissa_string: = str(mantissa).replace(".", "")
		for _i in range(exponent - mantissa_decimals):
			mantissa_string += "0"
		return mantissa_string



func to_plain_scientific() -> String:
	return str(mantissa) + "e" + str(exponent)



func to_scientific(no_decimals_on_small_values = false, force_decimals = false) -> String:
	if exponent < 10:
		var decimal_increments: float = 1 / (10 ** options.scientific_decimals / 10)
		var value: = str(snappedf(mantissa * 10 ** exponent, decimal_increments))
		var split: = value.split(".")

		if no_decimals_on_small_values:
			return Utils.add_commas_to_number(split[0])

		if split.size() > 1:
			for i in range(options.logarithmic_decimals):
				if split[1].length() < options.scientific_decimals:
					split[1] += "0"
			return split[0] + options.decimal_separator + split[1].substr(0, min(options.scientific_decimals, options.dynamic_numbers - split[0].length() if options.dynamic_decimals else options.scientific_decimals))
		else:
			return value
	else:
		var split: = str(mantissa).split(".")
		if split.size() == 1:
			split.append("")
		if force_decimals:
			for i in range(options.scientific_decimals):
				if split[1].length() < options.scientific_decimals:
					split[1] += "0"
		return split[0] + options.decimal_separator + split[1].substr(0, min(options.scientific_decimals, options.dynamic_numbers - 1 - str(exponent).length() if options.dynamic_decimals else options.scientific_decimals)) + "e" + str(exponent)



func to_logarithmic(no_decimals_on_small_values = false) -> String:
	var decimal_increments: float = 1 / (10 ** options.logarithmic_decimals / 10)
	if exponent < 3:
		var value: = str(snappedf(mantissa * 10 ** exponent, decimal_increments))
		var split: = value.split(".")
		if no_decimals_on_small_values:
			return split[0]
		if split.size() > 1:
			for i in range(options.logarithmic_decimals):
				if split[1].length() < options.logarithmic_decimals:
					split[1] += "0"
			return split[0] + options.decimal_separator + split[1].substr(0, min(options.logarithmic_decimals, options.dynamic_numbers - split[0].length() if options.dynamic_decimals else options.logarithmic_decimals))
		else:
			return value
	var dec: = str(snappedf(abs(log(mantissa) / log(10) * 10), decimal_increments))
	dec = dec.replace(".", "")
	for i in range(options.logarithmic_decimals):
		if dec.length() < options.logarithmic_decimals:
			dec += "0"
	var formated_exponent: = format_exponent(exponent)
	dec = dec.substr(0, min(options.logarithmic_decimals, options.dynamic_numbers - formated_exponent.length() if options.dynamic_decimals else options.logarithmic_decimals))
	return "e" + formated_exponent + options.decimal_separator + dec



func format_exponent(value) -> String:
	if value < 1000:
		return str(value)
	var string: = str(value)
	var string_mod: = string.length() % 3
	var output: = ""
	for i in range(0, string.length()):
		if i != 0 and i % 3 == string_mod:
			output += options.thousand_separator
		output += string[i]
	return output



func to_float() -> float:
	return snappedf(float(str(mantissa) + "e" + str(exponent)), 0.01)


func to_prefix(no_decimals_on_small_values = false, use_thousand_symbol = true, force_decimals = true, scientic_prefix = false) -> String:
	var number: float = mantissa
	if not scientic_prefix:
		var hundreds = 1
		for _i in range(exponent % 3):
			hundreds *= 10
		number *= hundreds

	var split: = str(number).split(".")
	if split.size() == 1:
		split.append("")
	if force_decimals:
		var max_decimals = max(max(options.small_decimals, options.thousand_decimals), options.big_decimals)
		for i in range(max_decimals):
			if split[1].length() < max_decimals:
				split[1] += "0"

	if no_decimals_on_small_values and exponent < 3:
		return split[0]
	elif exponent < 3:
		if options.small_decimals == 0 or split[1] == "":
			return split[0]
		else:
			return split[0] + options.decimal_separator + split[1].substr(0, min(options.small_decimals, options.dynamic_numbers - split[0].length() if options.dynamic_decimals else options.small_decimals))
	elif exponent < 6:
		if options.thousand_decimals == 0 or (split[1] == "" and use_thousand_symbol):
			return split[0]
		else:
			if use_thousand_symbol:
				for i in range(options.maximum_trailing_zeroes):
					if split[1].length() < options.maximum_trailing_zeroes:
						split[1] += "0"
				return split[0] + options.decimal_separator + split[1].substr(0, min(options.thousand_decimals, options.dynamic_numbers - split[0].length() if options.dynamic_decimals else 3))
			else:
				for i in range(options.maximum_trailing_zeroes):
					if split[1].length() < options.maximum_trailing_zeroes:
						split[1] += "0"
				return split[0] + options.thousand_separator + split[1].substr(0, 3)
	else:
		if options.big_decimals == 0 or split[1] == "":
			return split[0]
		else:
			return split[0] + options.decimal_separator + split[1].substr(0, min(options.big_decimals, options.dynamic_numbers - split[0].length() if options.dynamic_decimals else options.big_decimals))


func _latin_power(european_system) -> int:
	if european_system:
		@warning_ignore("integer_division")
		return int(exponent / 3) / 2
	@warning_ignore("integer_division")
	return int(exponent / 3) - 1


func _latin_prefix(european_system) -> String:
	var ones: = _latin_power(european_system) % 10
	var tens: = int(_latin_power(european_system) / floor(10)) % 10
	@warning_ignore("integer_division")
	var hundreds: = int(_latin_power(european_system) / 100) % 10
	@warning_ignore("integer_division")
	var millias: = int(_latin_power(european_system) / 1000) % 10

	var prefix: = ""
	if _latin_power(european_system) < 10:
		prefix = latin_special[ones] + options.reading_separator + latin_tens[tens] + options.reading_separator + latin_hundreds[hundreds]
	else:
		prefix = latin_hundreds[hundreds] + options.reading_separator + latin_ones[ones] + options.reading_separator + latin_tens[tens]

	for _i in range(millias):
		prefix = "millia" + options.reading_separator + prefix

	return prefix.lstrip(options.reading_separator).rstrip(options.reading_separator)


func _tillion_or_illion(european_system) -> String:
	if exponent < 6:
		return ""
	var power_kilo: = _latin_power(european_system) % 1000
	if power_kilo < 5 and power_kilo > 0 and _latin_power(european_system) < 1000:
		return ""
	if (
			power_kilo >= 7 and power_kilo <= 10
			or int(power_kilo / floor(10)) % 10 == 1
	):
		return "i"
	return "ti"


func _llion_or_lliard(european_system) -> String:
	if exponent < 6:
		return ""
	if int(exponent / floor(3)) % 2 == 1 and european_system:
		return "lliard"
	return "llion"


func get_long_name(european_system = false, prefix = "") -> String:
	if exponent < 6:
		return ""
	else:
		return prefix + _latin_prefix(european_system) + options.reading_separator + _tillion_or_illion(european_system) + _llion_or_lliard(european_system)


func duplicate() -> Big:
	return Big.new(mantissa, exponent)



func to_american_name(no_decimals_on_small_values = false) -> String:
	return to_long_name(no_decimals_on_small_values, false)



func to_european_name(no_decimals_on_small_values = false) -> String:
	return to_long_name(no_decimals_on_small_values, true)



func to_long_name(no_decimals_on_small_values = false, european_system = false) -> String:
	if exponent < 6:
		if exponent > 2:
			return to_prefix(no_decimals_on_small_values) + options.suffix_separator + options.thousand_name
		else:
			return to_prefix(no_decimals_on_small_values)

	var suffix = _latin_prefix(european_system) + options.reading_separator + _tillion_or_illion(european_system) + _llion_or_lliard(european_system)

	return to_prefix(no_decimals_on_small_values) + options.suffix_separator + suffix



func to_metric_symbol(no_decimals_on_small_values = false) -> String:
	@warning_ignore("integer_division")
	var target: = int(exponent / 3)

	if not suffixes_metric_symbol.has(str(target)):
		return to_scientific()
	else:
		return to_prefix(no_decimals_on_small_values) + options.suffix_separator + suffixes_metric_symbol[str(target)]



func to_metric_name(no_decimals_on_small_values = false) -> String:
	@warning_ignore("integer_division")
	var target: = int(exponent / 3)

	if not suffixes_metric_name.has(str(target)):
		return to_scientific()
	else:
		return to_prefix(no_decimals_on_small_values) + options.suffix_separator + suffixes_metric_name[str(target)]



func to_aa(no_decimals_on_small_values = false, use_thousand_symbol = true, force_decimals = false) -> String:
	@warning_ignore("integer_division")
	var target: = int(exponent / 3)
	var aa_index: = str(target)
	var suffix: = ""

	if not suffixes_aa.has(aa_index):
		var offset: = target + 22
		var base: = alphabet_aa.size()
		while offset > 0:
			offset -= 1
			var digit: = offset % base
			suffix = alphabet_aa[digit] + suffix
			offset /= base
		suffixes_aa[aa_index] = suffix
	else:
		suffix = suffixes_aa[aa_index]

	if not use_thousand_symbol and target == 1:
		suffix = ""

	var prefix = to_prefix(no_decimals_on_small_values, use_thousand_symbol, force_decimals)

	return prefix + options.suffix_separator + suffix
