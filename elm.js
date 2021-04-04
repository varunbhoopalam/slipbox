(function(scope){
'use strict';

function F(arity, fun, wrapper) {
  wrapper.a = arity;
  wrapper.f = fun;
  return wrapper;
}

function F2(fun) {
  return F(2, fun, function(a) { return function(b) { return fun(a,b); }; })
}
function F3(fun) {
  return F(3, fun, function(a) {
    return function(b) { return function(c) { return fun(a, b, c); }; };
  });
}
function F4(fun) {
  return F(4, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return fun(a, b, c, d); }; }; };
  });
}
function F5(fun) {
  return F(5, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return fun(a, b, c, d, e); }; }; }; };
  });
}
function F6(fun) {
  return F(6, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return fun(a, b, c, d, e, f); }; }; }; }; };
  });
}
function F7(fun) {
  return F(7, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return fun(a, b, c, d, e, f, g); }; }; }; }; }; };
  });
}
function F8(fun) {
  return F(8, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) {
    return fun(a, b, c, d, e, f, g, h); }; }; }; }; }; }; };
  });
}
function F9(fun) {
  return F(9, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) { return function(i) {
    return fun(a, b, c, d, e, f, g, h, i); }; }; }; }; }; }; }; };
  });
}

function A2(fun, a, b) {
  return fun.a === 2 ? fun.f(a, b) : fun(a)(b);
}
function A3(fun, a, b, c) {
  return fun.a === 3 ? fun.f(a, b, c) : fun(a)(b)(c);
}
function A4(fun, a, b, c, d) {
  return fun.a === 4 ? fun.f(a, b, c, d) : fun(a)(b)(c)(d);
}
function A5(fun, a, b, c, d, e) {
  return fun.a === 5 ? fun.f(a, b, c, d, e) : fun(a)(b)(c)(d)(e);
}
function A6(fun, a, b, c, d, e, f) {
  return fun.a === 6 ? fun.f(a, b, c, d, e, f) : fun(a)(b)(c)(d)(e)(f);
}
function A7(fun, a, b, c, d, e, f, g) {
  return fun.a === 7 ? fun.f(a, b, c, d, e, f, g) : fun(a)(b)(c)(d)(e)(f)(g);
}
function A8(fun, a, b, c, d, e, f, g, h) {
  return fun.a === 8 ? fun.f(a, b, c, d, e, f, g, h) : fun(a)(b)(c)(d)(e)(f)(g)(h);
}
function A9(fun, a, b, c, d, e, f, g, h, i) {
  return fun.a === 9 ? fun.f(a, b, c, d, e, f, g, h, i) : fun(a)(b)(c)(d)(e)(f)(g)(h)(i);
}




// EQUALITY

function _Utils_eq(x, y)
{
	for (
		var pair, stack = [], isEqual = _Utils_eqHelp(x, y, 0, stack);
		isEqual && (pair = stack.pop());
		isEqual = _Utils_eqHelp(pair.a, pair.b, 0, stack)
		)
	{}

	return isEqual;
}

function _Utils_eqHelp(x, y, depth, stack)
{
	if (x === y)
	{
		return true;
	}

	if (typeof x !== 'object' || x === null || y === null)
	{
		typeof x === 'function' && _Debug_crash(5);
		return false;
	}

	if (depth > 100)
	{
		stack.push(_Utils_Tuple2(x,y));
		return true;
	}

	/**_UNUSED/
	if (x.$ === 'Set_elm_builtin')
	{
		x = $elm$core$Set$toList(x);
		y = $elm$core$Set$toList(y);
	}
	if (x.$ === 'RBNode_elm_builtin' || x.$ === 'RBEmpty_elm_builtin')
	{
		x = $elm$core$Dict$toList(x);
		y = $elm$core$Dict$toList(y);
	}
	//*/

	/**/
	if (x.$ < 0)
	{
		x = $elm$core$Dict$toList(x);
		y = $elm$core$Dict$toList(y);
	}
	//*/

	for (var key in x)
	{
		if (!_Utils_eqHelp(x[key], y[key], depth + 1, stack))
		{
			return false;
		}
	}
	return true;
}

var _Utils_equal = F2(_Utils_eq);
var _Utils_notEqual = F2(function(a, b) { return !_Utils_eq(a,b); });



// COMPARISONS

// Code in Generate/JavaScript.hs, Basics.js, and List.js depends on
// the particular integer values assigned to LT, EQ, and GT.

function _Utils_cmp(x, y, ord)
{
	if (typeof x !== 'object')
	{
		return x === y ? /*EQ*/ 0 : x < y ? /*LT*/ -1 : /*GT*/ 1;
	}

	/**_UNUSED/
	if (x instanceof String)
	{
		var a = x.valueOf();
		var b = y.valueOf();
		return a === b ? 0 : a < b ? -1 : 1;
	}
	//*/

	/**/
	if (typeof x.$ === 'undefined')
	//*/
	/**_UNUSED/
	if (x.$[0] === '#')
	//*/
	{
		return (ord = _Utils_cmp(x.a, y.a))
			? ord
			: (ord = _Utils_cmp(x.b, y.b))
				? ord
				: _Utils_cmp(x.c, y.c);
	}

	// traverse conses until end of a list or a mismatch
	for (; x.b && y.b && !(ord = _Utils_cmp(x.a, y.a)); x = x.b, y = y.b) {} // WHILE_CONSES
	return ord || (x.b ? /*GT*/ 1 : y.b ? /*LT*/ -1 : /*EQ*/ 0);
}

var _Utils_lt = F2(function(a, b) { return _Utils_cmp(a, b) < 0; });
var _Utils_le = F2(function(a, b) { return _Utils_cmp(a, b) < 1; });
var _Utils_gt = F2(function(a, b) { return _Utils_cmp(a, b) > 0; });
var _Utils_ge = F2(function(a, b) { return _Utils_cmp(a, b) >= 0; });

var _Utils_compare = F2(function(x, y)
{
	var n = _Utils_cmp(x, y);
	return n < 0 ? $elm$core$Basics$LT : n ? $elm$core$Basics$GT : $elm$core$Basics$EQ;
});


// COMMON VALUES

var _Utils_Tuple0 = 0;
var _Utils_Tuple0_UNUSED = { $: '#0' };

function _Utils_Tuple2(a, b) { return { a: a, b: b }; }
function _Utils_Tuple2_UNUSED(a, b) { return { $: '#2', a: a, b: b }; }

function _Utils_Tuple3(a, b, c) { return { a: a, b: b, c: c }; }
function _Utils_Tuple3_UNUSED(a, b, c) { return { $: '#3', a: a, b: b, c: c }; }

function _Utils_chr(c) { return c; }
function _Utils_chr_UNUSED(c) { return new String(c); }


// RECORDS

function _Utils_update(oldRecord, updatedFields)
{
	var newRecord = {};

	for (var key in oldRecord)
	{
		newRecord[key] = oldRecord[key];
	}

	for (var key in updatedFields)
	{
		newRecord[key] = updatedFields[key];
	}

	return newRecord;
}


// APPEND

var _Utils_append = F2(_Utils_ap);

function _Utils_ap(xs, ys)
{
	// append Strings
	if (typeof xs === 'string')
	{
		return xs + ys;
	}

	// append Lists
	if (!xs.b)
	{
		return ys;
	}
	var root = _List_Cons(xs.a, ys);
	xs = xs.b
	for (var curr = root; xs.b; xs = xs.b) // WHILE_CONS
	{
		curr = curr.b = _List_Cons(xs.a, ys);
	}
	return root;
}



var _List_Nil = { $: 0 };
var _List_Nil_UNUSED = { $: '[]' };

function _List_Cons(hd, tl) { return { $: 1, a: hd, b: tl }; }
function _List_Cons_UNUSED(hd, tl) { return { $: '::', a: hd, b: tl }; }


var _List_cons = F2(_List_Cons);

function _List_fromArray(arr)
{
	var out = _List_Nil;
	for (var i = arr.length; i--; )
	{
		out = _List_Cons(arr[i], out);
	}
	return out;
}

function _List_toArray(xs)
{
	for (var out = []; xs.b; xs = xs.b) // WHILE_CONS
	{
		out.push(xs.a);
	}
	return out;
}

var _List_map2 = F3(function(f, xs, ys)
{
	for (var arr = []; xs.b && ys.b; xs = xs.b, ys = ys.b) // WHILE_CONSES
	{
		arr.push(A2(f, xs.a, ys.a));
	}
	return _List_fromArray(arr);
});

var _List_map3 = F4(function(f, xs, ys, zs)
{
	for (var arr = []; xs.b && ys.b && zs.b; xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A3(f, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_map4 = F5(function(f, ws, xs, ys, zs)
{
	for (var arr = []; ws.b && xs.b && ys.b && zs.b; ws = ws.b, xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A4(f, ws.a, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_map5 = F6(function(f, vs, ws, xs, ys, zs)
{
	for (var arr = []; vs.b && ws.b && xs.b && ys.b && zs.b; vs = vs.b, ws = ws.b, xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A5(f, vs.a, ws.a, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_sortBy = F2(function(f, xs)
{
	return _List_fromArray(_List_toArray(xs).sort(function(a, b) {
		return _Utils_cmp(f(a), f(b));
	}));
});

var _List_sortWith = F2(function(f, xs)
{
	return _List_fromArray(_List_toArray(xs).sort(function(a, b) {
		var ord = A2(f, a, b);
		return ord === $elm$core$Basics$EQ ? 0 : ord === $elm$core$Basics$LT ? -1 : 1;
	}));
});



var _JsArray_empty = [];

function _JsArray_singleton(value)
{
    return [value];
}

function _JsArray_length(array)
{
    return array.length;
}

var _JsArray_initialize = F3(function(size, offset, func)
{
    var result = new Array(size);

    for (var i = 0; i < size; i++)
    {
        result[i] = func(offset + i);
    }

    return result;
});

var _JsArray_initializeFromList = F2(function (max, ls)
{
    var result = new Array(max);

    for (var i = 0; i < max && ls.b; i++)
    {
        result[i] = ls.a;
        ls = ls.b;
    }

    result.length = i;
    return _Utils_Tuple2(result, ls);
});

var _JsArray_unsafeGet = F2(function(index, array)
{
    return array[index];
});

var _JsArray_unsafeSet = F3(function(index, value, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[index] = value;
    return result;
});

var _JsArray_push = F2(function(value, array)
{
    var length = array.length;
    var result = new Array(length + 1);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[length] = value;
    return result;
});

var _JsArray_foldl = F3(function(func, acc, array)
{
    var length = array.length;

    for (var i = 0; i < length; i++)
    {
        acc = A2(func, array[i], acc);
    }

    return acc;
});

var _JsArray_foldr = F3(function(func, acc, array)
{
    for (var i = array.length - 1; i >= 0; i--)
    {
        acc = A2(func, array[i], acc);
    }

    return acc;
});

var _JsArray_map = F2(function(func, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = func(array[i]);
    }

    return result;
});

var _JsArray_indexedMap = F3(function(func, offset, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = A2(func, offset + i, array[i]);
    }

    return result;
});

var _JsArray_slice = F3(function(from, to, array)
{
    return array.slice(from, to);
});

var _JsArray_appendN = F3(function(n, dest, source)
{
    var destLen = dest.length;
    var itemsToCopy = n - destLen;

    if (itemsToCopy > source.length)
    {
        itemsToCopy = source.length;
    }

    var size = destLen + itemsToCopy;
    var result = new Array(size);

    for (var i = 0; i < destLen; i++)
    {
        result[i] = dest[i];
    }

    for (var i = 0; i < itemsToCopy; i++)
    {
        result[i + destLen] = source[i];
    }

    return result;
});



// LOG

var _Debug_log = F2(function(tag, value)
{
	return value;
});

var _Debug_log_UNUSED = F2(function(tag, value)
{
	console.log(tag + ': ' + _Debug_toString(value));
	return value;
});


// TODOS

function _Debug_todo(moduleName, region)
{
	return function(message) {
		_Debug_crash(8, moduleName, region, message);
	};
}

function _Debug_todoCase(moduleName, region, value)
{
	return function(message) {
		_Debug_crash(9, moduleName, region, value, message);
	};
}


// TO STRING

function _Debug_toString(value)
{
	return '<internals>';
}

function _Debug_toString_UNUSED(value)
{
	return _Debug_toAnsiString(false, value);
}

function _Debug_toAnsiString(ansi, value)
{
	if (typeof value === 'function')
	{
		return _Debug_internalColor(ansi, '<function>');
	}

	if (typeof value === 'boolean')
	{
		return _Debug_ctorColor(ansi, value ? 'True' : 'False');
	}

	if (typeof value === 'number')
	{
		return _Debug_numberColor(ansi, value + '');
	}

	if (value instanceof String)
	{
		return _Debug_charColor(ansi, "'" + _Debug_addSlashes(value, true) + "'");
	}

	if (typeof value === 'string')
	{
		return _Debug_stringColor(ansi, '"' + _Debug_addSlashes(value, false) + '"');
	}

	if (typeof value === 'object' && '$' in value)
	{
		var tag = value.$;

		if (typeof tag === 'number')
		{
			return _Debug_internalColor(ansi, '<internals>');
		}

		if (tag[0] === '#')
		{
			var output = [];
			for (var k in value)
			{
				if (k === '$') continue;
				output.push(_Debug_toAnsiString(ansi, value[k]));
			}
			return '(' + output.join(',') + ')';
		}

		if (tag === 'Set_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Set')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Set$toList(value));
		}

		if (tag === 'RBNode_elm_builtin' || tag === 'RBEmpty_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Dict')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Dict$toList(value));
		}

		if (tag === 'Array_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Array')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Array$toList(value));
		}

		if (tag === '::' || tag === '[]')
		{
			var output = '[';

			value.b && (output += _Debug_toAnsiString(ansi, value.a), value = value.b)

			for (; value.b; value = value.b) // WHILE_CONS
			{
				output += ',' + _Debug_toAnsiString(ansi, value.a);
			}
			return output + ']';
		}

		var output = '';
		for (var i in value)
		{
			if (i === '$') continue;
			var str = _Debug_toAnsiString(ansi, value[i]);
			var c0 = str[0];
			var parenless = c0 === '{' || c0 === '(' || c0 === '[' || c0 === '<' || c0 === '"' || str.indexOf(' ') < 0;
			output += ' ' + (parenless ? str : '(' + str + ')');
		}
		return _Debug_ctorColor(ansi, tag) + output;
	}

	if (typeof DataView === 'function' && value instanceof DataView)
	{
		return _Debug_stringColor(ansi, '<' + value.byteLength + ' bytes>');
	}

	if (typeof File !== 'undefined' && value instanceof File)
	{
		return _Debug_internalColor(ansi, '<' + value.name + '>');
	}

	if (typeof value === 'object')
	{
		var output = [];
		for (var key in value)
		{
			var field = key[0] === '_' ? key.slice(1) : key;
			output.push(_Debug_fadeColor(ansi, field) + ' = ' + _Debug_toAnsiString(ansi, value[key]));
		}
		if (output.length === 0)
		{
			return '{}';
		}
		return '{ ' + output.join(', ') + ' }';
	}

	return _Debug_internalColor(ansi, '<internals>');
}

function _Debug_addSlashes(str, isChar)
{
	var s = str
		.replace(/\\/g, '\\\\')
		.replace(/\n/g, '\\n')
		.replace(/\t/g, '\\t')
		.replace(/\r/g, '\\r')
		.replace(/\v/g, '\\v')
		.replace(/\0/g, '\\0');

	if (isChar)
	{
		return s.replace(/\'/g, '\\\'');
	}
	else
	{
		return s.replace(/\"/g, '\\"');
	}
}

function _Debug_ctorColor(ansi, string)
{
	return ansi ? '\x1b[96m' + string + '\x1b[0m' : string;
}

function _Debug_numberColor(ansi, string)
{
	return ansi ? '\x1b[95m' + string + '\x1b[0m' : string;
}

function _Debug_stringColor(ansi, string)
{
	return ansi ? '\x1b[93m' + string + '\x1b[0m' : string;
}

function _Debug_charColor(ansi, string)
{
	return ansi ? '\x1b[92m' + string + '\x1b[0m' : string;
}

function _Debug_fadeColor(ansi, string)
{
	return ansi ? '\x1b[37m' + string + '\x1b[0m' : string;
}

function _Debug_internalColor(ansi, string)
{
	return ansi ? '\x1b[36m' + string + '\x1b[0m' : string;
}

function _Debug_toHexDigit(n)
{
	return String.fromCharCode(n < 10 ? 48 + n : 55 + n);
}


// CRASH


function _Debug_crash(identifier)
{
	throw new Error('https://github.com/elm/core/blob/1.0.0/hints/' + identifier + '.md');
}


function _Debug_crash_UNUSED(identifier, fact1, fact2, fact3, fact4)
{
	switch(identifier)
	{
		case 0:
			throw new Error('What node should I take over? In JavaScript I need something like:\n\n    Elm.Main.init({\n        node: document.getElementById("elm-node")\n    })\n\nYou need to do this with any Browser.sandbox or Browser.element program.');

		case 1:
			throw new Error('Browser.application programs cannot handle URLs like this:\n\n    ' + document.location.href + '\n\nWhat is the root? The root of your file system? Try looking at this program with `elm reactor` or some other server.');

		case 2:
			var jsonErrorString = fact1;
			throw new Error('Problem with the flags given to your Elm program on initialization.\n\n' + jsonErrorString);

		case 3:
			var portName = fact1;
			throw new Error('There can only be one port named `' + portName + '`, but your program has multiple.');

		case 4:
			var portName = fact1;
			var problem = fact2;
			throw new Error('Trying to send an unexpected type of value through port `' + portName + '`:\n' + problem);

		case 5:
			throw new Error('Trying to use `(==)` on functions.\nThere is no way to know if functions are "the same" in the Elm sense.\nRead more about this at https://package.elm-lang.org/packages/elm/core/latest/Basics#== which describes why it is this way and what the better version will look like.');

		case 6:
			var moduleName = fact1;
			throw new Error('Your page is loading multiple Elm scripts with a module named ' + moduleName + '. Maybe a duplicate script is getting loaded accidentally? If not, rename one of them so I know which is which!');

		case 8:
			var moduleName = fact1;
			var region = fact2;
			var message = fact3;
			throw new Error('TODO in module `' + moduleName + '` ' + _Debug_regionToString(region) + '\n\n' + message);

		case 9:
			var moduleName = fact1;
			var region = fact2;
			var value = fact3;
			var message = fact4;
			throw new Error(
				'TODO in module `' + moduleName + '` from the `case` expression '
				+ _Debug_regionToString(region) + '\n\nIt received the following value:\n\n    '
				+ _Debug_toString(value).replace('\n', '\n    ')
				+ '\n\nBut the branch that handles it says:\n\n    ' + message.replace('\n', '\n    ')
			);

		case 10:
			throw new Error('Bug in https://github.com/elm/virtual-dom/issues');

		case 11:
			throw new Error('Cannot perform mod 0. Division by zero error.');
	}
}

function _Debug_regionToString(region)
{
	if (region.dJ.bG === region.el.bG)
	{
		return 'on line ' + region.dJ.bG;
	}
	return 'on lines ' + region.dJ.bG + ' through ' + region.el.bG;
}



// MATH

var _Basics_add = F2(function(a, b) { return a + b; });
var _Basics_sub = F2(function(a, b) { return a - b; });
var _Basics_mul = F2(function(a, b) { return a * b; });
var _Basics_fdiv = F2(function(a, b) { return a / b; });
var _Basics_idiv = F2(function(a, b) { return (a / b) | 0; });
var _Basics_pow = F2(Math.pow);

var _Basics_remainderBy = F2(function(b, a) { return a % b; });

// https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/divmodnote-letter.pdf
var _Basics_modBy = F2(function(modulus, x)
{
	var answer = x % modulus;
	return modulus === 0
		? _Debug_crash(11)
		:
	((answer > 0 && modulus < 0) || (answer < 0 && modulus > 0))
		? answer + modulus
		: answer;
});


// TRIGONOMETRY

var _Basics_pi = Math.PI;
var _Basics_e = Math.E;
var _Basics_cos = Math.cos;
var _Basics_sin = Math.sin;
var _Basics_tan = Math.tan;
var _Basics_acos = Math.acos;
var _Basics_asin = Math.asin;
var _Basics_atan = Math.atan;
var _Basics_atan2 = F2(Math.atan2);


// MORE MATH

function _Basics_toFloat(x) { return x; }
function _Basics_truncate(n) { return n | 0; }
function _Basics_isInfinite(n) { return n === Infinity || n === -Infinity; }

var _Basics_ceiling = Math.ceil;
var _Basics_floor = Math.floor;
var _Basics_round = Math.round;
var _Basics_sqrt = Math.sqrt;
var _Basics_log = Math.log;
var _Basics_isNaN = isNaN;


// BOOLEANS

function _Basics_not(bool) { return !bool; }
var _Basics_and = F2(function(a, b) { return a && b; });
var _Basics_or  = F2(function(a, b) { return a || b; });
var _Basics_xor = F2(function(a, b) { return a !== b; });



var _String_cons = F2(function(chr, str)
{
	return chr + str;
});

function _String_uncons(string)
{
	var word = string.charCodeAt(0);
	return !isNaN(word)
		? $elm$core$Maybe$Just(
			0xD800 <= word && word <= 0xDBFF
				? _Utils_Tuple2(_Utils_chr(string[0] + string[1]), string.slice(2))
				: _Utils_Tuple2(_Utils_chr(string[0]), string.slice(1))
		)
		: $elm$core$Maybe$Nothing;
}

var _String_append = F2(function(a, b)
{
	return a + b;
});

function _String_length(str)
{
	return str.length;
}

var _String_map = F2(function(func, string)
{
	var len = string.length;
	var array = new Array(len);
	var i = 0;
	while (i < len)
	{
		var word = string.charCodeAt(i);
		if (0xD800 <= word && word <= 0xDBFF)
		{
			array[i] = func(_Utils_chr(string[i] + string[i+1]));
			i += 2;
			continue;
		}
		array[i] = func(_Utils_chr(string[i]));
		i++;
	}
	return array.join('');
});

var _String_filter = F2(function(isGood, str)
{
	var arr = [];
	var len = str.length;
	var i = 0;
	while (i < len)
	{
		var char = str[i];
		var word = str.charCodeAt(i);
		i++;
		if (0xD800 <= word && word <= 0xDBFF)
		{
			char += str[i];
			i++;
		}

		if (isGood(_Utils_chr(char)))
		{
			arr.push(char);
		}
	}
	return arr.join('');
});

function _String_reverse(str)
{
	var len = str.length;
	var arr = new Array(len);
	var i = 0;
	while (i < len)
	{
		var word = str.charCodeAt(i);
		if (0xD800 <= word && word <= 0xDBFF)
		{
			arr[len - i] = str[i + 1];
			i++;
			arr[len - i] = str[i - 1];
			i++;
		}
		else
		{
			arr[len - i] = str[i];
			i++;
		}
	}
	return arr.join('');
}

var _String_foldl = F3(function(func, state, string)
{
	var len = string.length;
	var i = 0;
	while (i < len)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		i++;
		if (0xD800 <= word && word <= 0xDBFF)
		{
			char += string[i];
			i++;
		}
		state = A2(func, _Utils_chr(char), state);
	}
	return state;
});

var _String_foldr = F3(function(func, state, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		state = A2(func, _Utils_chr(char), state);
	}
	return state;
});

var _String_split = F2(function(sep, str)
{
	return str.split(sep);
});

var _String_join = F2(function(sep, strs)
{
	return strs.join(sep);
});

var _String_slice = F3(function(start, end, str) {
	return str.slice(start, end);
});

function _String_trim(str)
{
	return str.trim();
}

function _String_trimLeft(str)
{
	return str.replace(/^\s+/, '');
}

function _String_trimRight(str)
{
	return str.replace(/\s+$/, '');
}

function _String_words(str)
{
	return _List_fromArray(str.trim().split(/\s+/g));
}

function _String_lines(str)
{
	return _List_fromArray(str.split(/\r\n|\r|\n/g));
}

function _String_toUpper(str)
{
	return str.toUpperCase();
}

function _String_toLower(str)
{
	return str.toLowerCase();
}

var _String_any = F2(function(isGood, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		if (isGood(_Utils_chr(char)))
		{
			return true;
		}
	}
	return false;
});

var _String_all = F2(function(isGood, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		if (!isGood(_Utils_chr(char)))
		{
			return false;
		}
	}
	return true;
});

var _String_contains = F2(function(sub, str)
{
	return str.indexOf(sub) > -1;
});

var _String_startsWith = F2(function(sub, str)
{
	return str.indexOf(sub) === 0;
});

var _String_endsWith = F2(function(sub, str)
{
	return str.length >= sub.length &&
		str.lastIndexOf(sub) === str.length - sub.length;
});

var _String_indexes = F2(function(sub, str)
{
	var subLen = sub.length;

	if (subLen < 1)
	{
		return _List_Nil;
	}

	var i = 0;
	var is = [];

	while ((i = str.indexOf(sub, i)) > -1)
	{
		is.push(i);
		i = i + subLen;
	}

	return _List_fromArray(is);
});


// TO STRING

function _String_fromNumber(number)
{
	return number + '';
}


// INT CONVERSIONS

function _String_toInt(str)
{
	var total = 0;
	var code0 = str.charCodeAt(0);
	var start = code0 == 0x2B /* + */ || code0 == 0x2D /* - */ ? 1 : 0;

	for (var i = start; i < str.length; ++i)
	{
		var code = str.charCodeAt(i);
		if (code < 0x30 || 0x39 < code)
		{
			return $elm$core$Maybe$Nothing;
		}
		total = 10 * total + code - 0x30;
	}

	return i == start
		? $elm$core$Maybe$Nothing
		: $elm$core$Maybe$Just(code0 == 0x2D ? -total : total);
}


// FLOAT CONVERSIONS

function _String_toFloat(s)
{
	// check if it is a hex, octal, or binary number
	if (s.length === 0 || /[\sxbo]/.test(s))
	{
		return $elm$core$Maybe$Nothing;
	}
	var n = +s;
	// faster isNaN check
	return n === n ? $elm$core$Maybe$Just(n) : $elm$core$Maybe$Nothing;
}

function _String_fromList(chars)
{
	return _List_toArray(chars).join('');
}




function _Char_toCode(char)
{
	var code = char.charCodeAt(0);
	if (0xD800 <= code && code <= 0xDBFF)
	{
		return (code - 0xD800) * 0x400 + char.charCodeAt(1) - 0xDC00 + 0x10000
	}
	return code;
}

function _Char_fromCode(code)
{
	return _Utils_chr(
		(code < 0 || 0x10FFFF < code)
			? '\uFFFD'
			:
		(code <= 0xFFFF)
			? String.fromCharCode(code)
			:
		(code -= 0x10000,
			String.fromCharCode(Math.floor(code / 0x400) + 0xD800, code % 0x400 + 0xDC00)
		)
	);
}

function _Char_toUpper(char)
{
	return _Utils_chr(char.toUpperCase());
}

function _Char_toLower(char)
{
	return _Utils_chr(char.toLowerCase());
}

function _Char_toLocaleUpper(char)
{
	return _Utils_chr(char.toLocaleUpperCase());
}

function _Char_toLocaleLower(char)
{
	return _Utils_chr(char.toLocaleLowerCase());
}



/**_UNUSED/
function _Json_errorToString(error)
{
	return $elm$json$Json$Decode$errorToString(error);
}
//*/


// CORE DECODERS

function _Json_succeed(msg)
{
	return {
		$: 0,
		a: msg
	};
}

function _Json_fail(msg)
{
	return {
		$: 1,
		a: msg
	};
}

function _Json_decodePrim(decoder)
{
	return { $: 2, b: decoder };
}

var _Json_decodeInt = _Json_decodePrim(function(value) {
	return (typeof value !== 'number')
		? _Json_expecting('an INT', value)
		:
	(-2147483647 < value && value < 2147483647 && (value | 0) === value)
		? $elm$core$Result$Ok(value)
		:
	(isFinite(value) && !(value % 1))
		? $elm$core$Result$Ok(value)
		: _Json_expecting('an INT', value);
});

var _Json_decodeBool = _Json_decodePrim(function(value) {
	return (typeof value === 'boolean')
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a BOOL', value);
});

var _Json_decodeFloat = _Json_decodePrim(function(value) {
	return (typeof value === 'number')
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a FLOAT', value);
});

var _Json_decodeValue = _Json_decodePrim(function(value) {
	return $elm$core$Result$Ok(_Json_wrap(value));
});

var _Json_decodeString = _Json_decodePrim(function(value) {
	return (typeof value === 'string')
		? $elm$core$Result$Ok(value)
		: (value instanceof String)
			? $elm$core$Result$Ok(value + '')
			: _Json_expecting('a STRING', value);
});

function _Json_decodeList(decoder) { return { $: 3, b: decoder }; }
function _Json_decodeArray(decoder) { return { $: 4, b: decoder }; }

function _Json_decodeNull(value) { return { $: 5, c: value }; }

var _Json_decodeField = F2(function(field, decoder)
{
	return {
		$: 6,
		d: field,
		b: decoder
	};
});

var _Json_decodeIndex = F2(function(index, decoder)
{
	return {
		$: 7,
		e: index,
		b: decoder
	};
});

function _Json_decodeKeyValuePairs(decoder)
{
	return {
		$: 8,
		b: decoder
	};
}

function _Json_mapMany(f, decoders)
{
	return {
		$: 9,
		f: f,
		g: decoders
	};
}

var _Json_andThen = F2(function(callback, decoder)
{
	return {
		$: 10,
		b: decoder,
		h: callback
	};
});

function _Json_oneOf(decoders)
{
	return {
		$: 11,
		g: decoders
	};
}


// DECODING OBJECTS

var _Json_map1 = F2(function(f, d1)
{
	return _Json_mapMany(f, [d1]);
});

var _Json_map2 = F3(function(f, d1, d2)
{
	return _Json_mapMany(f, [d1, d2]);
});

var _Json_map3 = F4(function(f, d1, d2, d3)
{
	return _Json_mapMany(f, [d1, d2, d3]);
});

var _Json_map4 = F5(function(f, d1, d2, d3, d4)
{
	return _Json_mapMany(f, [d1, d2, d3, d4]);
});

var _Json_map5 = F6(function(f, d1, d2, d3, d4, d5)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5]);
});

var _Json_map6 = F7(function(f, d1, d2, d3, d4, d5, d6)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6]);
});

var _Json_map7 = F8(function(f, d1, d2, d3, d4, d5, d6, d7)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7]);
});

var _Json_map8 = F9(function(f, d1, d2, d3, d4, d5, d6, d7, d8)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7, d8]);
});


// DECODE

var _Json_runOnString = F2(function(decoder, string)
{
	try
	{
		var value = JSON.parse(string);
		return _Json_runHelp(decoder, value);
	}
	catch (e)
	{
		return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, 'This is not valid JSON! ' + e.message, _Json_wrap(string)));
	}
});

var _Json_run = F2(function(decoder, value)
{
	return _Json_runHelp(decoder, _Json_unwrap(value));
});

function _Json_runHelp(decoder, value)
{
	switch (decoder.$)
	{
		case 2:
			return decoder.b(value);

		case 5:
			return (value === null)
				? $elm$core$Result$Ok(decoder.c)
				: _Json_expecting('null', value);

		case 3:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('a LIST', value);
			}
			return _Json_runArrayDecoder(decoder.b, value, _List_fromArray);

		case 4:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			return _Json_runArrayDecoder(decoder.b, value, _Json_toElmArray);

		case 6:
			var field = decoder.d;
			if (typeof value !== 'object' || value === null || !(field in value))
			{
				return _Json_expecting('an OBJECT with a field named `' + field + '`', value);
			}
			var result = _Json_runHelp(decoder.b, value[field]);
			return ($elm$core$Result$isOk(result)) ? result : $elm$core$Result$Err(A2($elm$json$Json$Decode$Field, field, result.a));

		case 7:
			var index = decoder.e;
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			if (index >= value.length)
			{
				return _Json_expecting('a LONGER array. Need index ' + index + ' but only see ' + value.length + ' entries', value);
			}
			var result = _Json_runHelp(decoder.b, value[index]);
			return ($elm$core$Result$isOk(result)) ? result : $elm$core$Result$Err(A2($elm$json$Json$Decode$Index, index, result.a));

		case 8:
			if (typeof value !== 'object' || value === null || _Json_isArray(value))
			{
				return _Json_expecting('an OBJECT', value);
			}

			var keyValuePairs = _List_Nil;
			// TODO test perf of Object.keys and switch when support is good enough
			for (var key in value)
			{
				if (value.hasOwnProperty(key))
				{
					var result = _Json_runHelp(decoder.b, value[key]);
					if (!$elm$core$Result$isOk(result))
					{
						return $elm$core$Result$Err(A2($elm$json$Json$Decode$Field, key, result.a));
					}
					keyValuePairs = _List_Cons(_Utils_Tuple2(key, result.a), keyValuePairs);
				}
			}
			return $elm$core$Result$Ok($elm$core$List$reverse(keyValuePairs));

		case 9:
			var answer = decoder.f;
			var decoders = decoder.g;
			for (var i = 0; i < decoders.length; i++)
			{
				var result = _Json_runHelp(decoders[i], value);
				if (!$elm$core$Result$isOk(result))
				{
					return result;
				}
				answer = answer(result.a);
			}
			return $elm$core$Result$Ok(answer);

		case 10:
			var result = _Json_runHelp(decoder.b, value);
			return (!$elm$core$Result$isOk(result))
				? result
				: _Json_runHelp(decoder.h(result.a), value);

		case 11:
			var errors = _List_Nil;
			for (var temp = decoder.g; temp.b; temp = temp.b) // WHILE_CONS
			{
				var result = _Json_runHelp(temp.a, value);
				if ($elm$core$Result$isOk(result))
				{
					return result;
				}
				errors = _List_Cons(result.a, errors);
			}
			return $elm$core$Result$Err($elm$json$Json$Decode$OneOf($elm$core$List$reverse(errors)));

		case 1:
			return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, decoder.a, _Json_wrap(value)));

		case 0:
			return $elm$core$Result$Ok(decoder.a);
	}
}

function _Json_runArrayDecoder(decoder, value, toElmValue)
{
	var len = value.length;
	var array = new Array(len);
	for (var i = 0; i < len; i++)
	{
		var result = _Json_runHelp(decoder, value[i]);
		if (!$elm$core$Result$isOk(result))
		{
			return $elm$core$Result$Err(A2($elm$json$Json$Decode$Index, i, result.a));
		}
		array[i] = result.a;
	}
	return $elm$core$Result$Ok(toElmValue(array));
}

function _Json_isArray(value)
{
	return Array.isArray(value) || (typeof FileList !== 'undefined' && value instanceof FileList);
}

function _Json_toElmArray(array)
{
	return A2($elm$core$Array$initialize, array.length, function(i) { return array[i]; });
}

function _Json_expecting(type, value)
{
	return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, 'Expecting ' + type, _Json_wrap(value)));
}


// EQUALITY

function _Json_equality(x, y)
{
	if (x === y)
	{
		return true;
	}

	if (x.$ !== y.$)
	{
		return false;
	}

	switch (x.$)
	{
		case 0:
		case 1:
			return x.a === y.a;

		case 2:
			return x.b === y.b;

		case 5:
			return x.c === y.c;

		case 3:
		case 4:
		case 8:
			return _Json_equality(x.b, y.b);

		case 6:
			return x.d === y.d && _Json_equality(x.b, y.b);

		case 7:
			return x.e === y.e && _Json_equality(x.b, y.b);

		case 9:
			return x.f === y.f && _Json_listEquality(x.g, y.g);

		case 10:
			return x.h === y.h && _Json_equality(x.b, y.b);

		case 11:
			return _Json_listEquality(x.g, y.g);
	}
}

function _Json_listEquality(aDecoders, bDecoders)
{
	var len = aDecoders.length;
	if (len !== bDecoders.length)
	{
		return false;
	}
	for (var i = 0; i < len; i++)
	{
		if (!_Json_equality(aDecoders[i], bDecoders[i]))
		{
			return false;
		}
	}
	return true;
}


// ENCODE

var _Json_encode = F2(function(indentLevel, value)
{
	return JSON.stringify(_Json_unwrap(value), null, indentLevel) + '';
});

function _Json_wrap_UNUSED(value) { return { $: 0, a: value }; }
function _Json_unwrap_UNUSED(value) { return value.a; }

function _Json_wrap(value) { return value; }
function _Json_unwrap(value) { return value; }

function _Json_emptyArray() { return []; }
function _Json_emptyObject() { return {}; }

var _Json_addField = F3(function(key, value, object)
{
	object[key] = _Json_unwrap(value);
	return object;
});

function _Json_addEntry(func)
{
	return F2(function(entry, array)
	{
		array.push(_Json_unwrap(func(entry)));
		return array;
	});
}

var _Json_encodeNull = _Json_wrap(null);



// TASKS

function _Scheduler_succeed(value)
{
	return {
		$: 0,
		a: value
	};
}

function _Scheduler_fail(error)
{
	return {
		$: 1,
		a: error
	};
}

function _Scheduler_binding(callback)
{
	return {
		$: 2,
		b: callback,
		c: null
	};
}

var _Scheduler_andThen = F2(function(callback, task)
{
	return {
		$: 3,
		b: callback,
		d: task
	};
});

var _Scheduler_onError = F2(function(callback, task)
{
	return {
		$: 4,
		b: callback,
		d: task
	};
});

function _Scheduler_receive(callback)
{
	return {
		$: 5,
		b: callback
	};
}


// PROCESSES

var _Scheduler_guid = 0;

function _Scheduler_rawSpawn(task)
{
	var proc = {
		$: 0,
		e: _Scheduler_guid++,
		f: task,
		g: null,
		h: []
	};

	_Scheduler_enqueue(proc);

	return proc;
}

function _Scheduler_spawn(task)
{
	return _Scheduler_binding(function(callback) {
		callback(_Scheduler_succeed(_Scheduler_rawSpawn(task)));
	});
}

function _Scheduler_rawSend(proc, msg)
{
	proc.h.push(msg);
	_Scheduler_enqueue(proc);
}

var _Scheduler_send = F2(function(proc, msg)
{
	return _Scheduler_binding(function(callback) {
		_Scheduler_rawSend(proc, msg);
		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
});

function _Scheduler_kill(proc)
{
	return _Scheduler_binding(function(callback) {
		var task = proc.f;
		if (task.$ === 2 && task.c)
		{
			task.c();
		}

		proc.f = null;

		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
}


/* STEP PROCESSES

type alias Process =
  { $ : tag
  , id : unique_id
  , root : Task
  , stack : null | { $: SUCCEED | FAIL, a: callback, b: stack }
  , mailbox : [msg]
  }

*/


var _Scheduler_working = false;
var _Scheduler_queue = [];


function _Scheduler_enqueue(proc)
{
	_Scheduler_queue.push(proc);
	if (_Scheduler_working)
	{
		return;
	}
	_Scheduler_working = true;
	while (proc = _Scheduler_queue.shift())
	{
		_Scheduler_step(proc);
	}
	_Scheduler_working = false;
}


function _Scheduler_step(proc)
{
	while (proc.f)
	{
		var rootTag = proc.f.$;
		if (rootTag === 0 || rootTag === 1)
		{
			while (proc.g && proc.g.$ !== rootTag)
			{
				proc.g = proc.g.i;
			}
			if (!proc.g)
			{
				return;
			}
			proc.f = proc.g.b(proc.f.a);
			proc.g = proc.g.i;
		}
		else if (rootTag === 2)
		{
			proc.f.c = proc.f.b(function(newRoot) {
				proc.f = newRoot;
				_Scheduler_enqueue(proc);
			});
			return;
		}
		else if (rootTag === 5)
		{
			if (proc.h.length === 0)
			{
				return;
			}
			proc.f = proc.f.b(proc.h.shift());
		}
		else // if (rootTag === 3 || rootTag === 4)
		{
			proc.g = {
				$: rootTag === 3 ? 0 : 1,
				b: proc.f.b,
				i: proc.g
			};
			proc.f = proc.f.d;
		}
	}
}



function _Process_sleep(time)
{
	return _Scheduler_binding(function(callback) {
		var id = setTimeout(function() {
			callback(_Scheduler_succeed(_Utils_Tuple0));
		}, time);

		return function() { clearTimeout(id); };
	});
}




// PROGRAMS


var _Platform_worker = F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.gK,
		impl.h8,
		impl.hK,
		function() { return function() {} }
	);
});



// INITIALIZE A PROGRAM


function _Platform_initialize(flagDecoder, args, init, update, subscriptions, stepperBuilder)
{
	var result = A2(_Json_run, flagDecoder, _Json_wrap(args ? args['flags'] : undefined));
	$elm$core$Result$isOk(result) || _Debug_crash(2 /**_UNUSED/, _Json_errorToString(result.a) /**/);
	var managers = {};
	var initPair = init(result.a);
	var model = initPair.a;
	var stepper = stepperBuilder(sendToApp, model);
	var ports = _Platform_setupEffects(managers, sendToApp);

	function sendToApp(msg, viewMetadata)
	{
		var pair = A2(update, msg, model);
		stepper(model = pair.a, viewMetadata);
		_Platform_enqueueEffects(managers, pair.b, subscriptions(model));
	}

	_Platform_enqueueEffects(managers, initPair.b, subscriptions(model));

	return ports ? { ports: ports } : {};
}



// TRACK PRELOADS
//
// This is used by code in elm/browser and elm/http
// to register any HTTP requests that are triggered by init.
//


var _Platform_preload;


function _Platform_registerPreload(url)
{
	_Platform_preload.add(url);
}



// EFFECT MANAGERS


var _Platform_effectManagers = {};


function _Platform_setupEffects(managers, sendToApp)
{
	var ports;

	// setup all necessary effect managers
	for (var key in _Platform_effectManagers)
	{
		var manager = _Platform_effectManagers[key];

		if (manager.a)
		{
			ports = ports || {};
			ports[key] = manager.a(key, sendToApp);
		}

		managers[key] = _Platform_instantiateManager(manager, sendToApp);
	}

	return ports;
}


function _Platform_createManager(init, onEffects, onSelfMsg, cmdMap, subMap)
{
	return {
		b: init,
		c: onEffects,
		d: onSelfMsg,
		e: cmdMap,
		f: subMap
	};
}


function _Platform_instantiateManager(info, sendToApp)
{
	var router = {
		g: sendToApp,
		h: undefined
	};

	var onEffects = info.c;
	var onSelfMsg = info.d;
	var cmdMap = info.e;
	var subMap = info.f;

	function loop(state)
	{
		return A2(_Scheduler_andThen, loop, _Scheduler_receive(function(msg)
		{
			var value = msg.a;

			if (msg.$ === 0)
			{
				return A3(onSelfMsg, router, value, state);
			}

			return cmdMap && subMap
				? A4(onEffects, router, value.i, value.j, state)
				: A3(onEffects, router, cmdMap ? value.i : value.j, state);
		}));
	}

	return router.h = _Scheduler_rawSpawn(A2(_Scheduler_andThen, loop, info.b));
}



// ROUTING


var _Platform_sendToApp = F2(function(router, msg)
{
	return _Scheduler_binding(function(callback)
	{
		router.g(msg);
		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
});


var _Platform_sendToSelf = F2(function(router, msg)
{
	return A2(_Scheduler_send, router.h, {
		$: 0,
		a: msg
	});
});



// BAGS


function _Platform_leaf(home)
{
	return function(value)
	{
		return {
			$: 1,
			k: home,
			l: value
		};
	};
}


function _Platform_batch(list)
{
	return {
		$: 2,
		m: list
	};
}


var _Platform_map = F2(function(tagger, bag)
{
	return {
		$: 3,
		n: tagger,
		o: bag
	}
});



// PIPE BAGS INTO EFFECT MANAGERS
//
// Effects must be queued!
//
// Say your init contains a synchronous command, like Time.now or Time.here
//
//   - This will produce a batch of effects (FX_1)
//   - The synchronous task triggers the subsequent `update` call
//   - This will produce a batch of effects (FX_2)
//
// If we just start dispatching FX_2, subscriptions from FX_2 can be processed
// before subscriptions from FX_1. No good! Earlier versions of this code had
// this problem, leading to these reports:
//
//   https://github.com/elm/core/issues/980
//   https://github.com/elm/core/pull/981
//   https://github.com/elm/compiler/issues/1776
//
// The queue is necessary to avoid ordering issues for synchronous commands.


// Why use true/false here? Why not just check the length of the queue?
// The goal is to detect "are we currently dispatching effects?" If we
// are, we need to bail and let the ongoing while loop handle things.
//
// Now say the queue has 1 element. When we dequeue the final element,
// the queue will be empty, but we are still actively dispatching effects.
// So you could get queue jumping in a really tricky category of cases.
//
var _Platform_effectsQueue = [];
var _Platform_effectsActive = false;


function _Platform_enqueueEffects(managers, cmdBag, subBag)
{
	_Platform_effectsQueue.push({ p: managers, q: cmdBag, r: subBag });

	if (_Platform_effectsActive) return;

	_Platform_effectsActive = true;
	for (var fx; fx = _Platform_effectsQueue.shift(); )
	{
		_Platform_dispatchEffects(fx.p, fx.q, fx.r);
	}
	_Platform_effectsActive = false;
}


function _Platform_dispatchEffects(managers, cmdBag, subBag)
{
	var effectsDict = {};
	_Platform_gatherEffects(true, cmdBag, effectsDict, null);
	_Platform_gatherEffects(false, subBag, effectsDict, null);

	for (var home in managers)
	{
		_Scheduler_rawSend(managers[home], {
			$: 'fx',
			a: effectsDict[home] || { i: _List_Nil, j: _List_Nil }
		});
	}
}


function _Platform_gatherEffects(isCmd, bag, effectsDict, taggers)
{
	switch (bag.$)
	{
		case 1:
			var home = bag.k;
			var effect = _Platform_toEffect(isCmd, home, taggers, bag.l);
			effectsDict[home] = _Platform_insert(isCmd, effect, effectsDict[home]);
			return;

		case 2:
			for (var list = bag.m; list.b; list = list.b) // WHILE_CONS
			{
				_Platform_gatherEffects(isCmd, list.a, effectsDict, taggers);
			}
			return;

		case 3:
			_Platform_gatherEffects(isCmd, bag.o, effectsDict, {
				s: bag.n,
				t: taggers
			});
			return;
	}
}


function _Platform_toEffect(isCmd, home, taggers, value)
{
	function applyTaggers(x)
	{
		for (var temp = taggers; temp; temp = temp.t)
		{
			x = temp.s(x);
		}
		return x;
	}

	var map = isCmd
		? _Platform_effectManagers[home].e
		: _Platform_effectManagers[home].f;

	return A2(map, applyTaggers, value)
}


function _Platform_insert(isCmd, newEffect, effects)
{
	effects = effects || { i: _List_Nil, j: _List_Nil };

	isCmd
		? (effects.i = _List_Cons(newEffect, effects.i))
		: (effects.j = _List_Cons(newEffect, effects.j));

	return effects;
}



// PORTS


function _Platform_checkPortName(name)
{
	if (_Platform_effectManagers[name])
	{
		_Debug_crash(3, name)
	}
}



// OUTGOING PORTS


function _Platform_outgoingPort(name, converter)
{
	_Platform_checkPortName(name);
	_Platform_effectManagers[name] = {
		e: _Platform_outgoingPortMap,
		u: converter,
		a: _Platform_setupOutgoingPort
	};
	return _Platform_leaf(name);
}


var _Platform_outgoingPortMap = F2(function(tagger, value) { return value; });


function _Platform_setupOutgoingPort(name)
{
	var subs = [];
	var converter = _Platform_effectManagers[name].u;

	// CREATE MANAGER

	var init = _Process_sleep(0);

	_Platform_effectManagers[name].b = init;
	_Platform_effectManagers[name].c = F3(function(router, cmdList, state)
	{
		for ( ; cmdList.b; cmdList = cmdList.b) // WHILE_CONS
		{
			// grab a separate reference to subs in case unsubscribe is called
			var currentSubs = subs;
			var value = _Json_unwrap(converter(cmdList.a));
			for (var i = 0; i < currentSubs.length; i++)
			{
				currentSubs[i](value);
			}
		}
		return init;
	});

	// PUBLIC API

	function subscribe(callback)
	{
		subs.push(callback);
	}

	function unsubscribe(callback)
	{
		// copy subs into a new array in case unsubscribe is called within a
		// subscribed callback
		subs = subs.slice();
		var index = subs.indexOf(callback);
		if (index >= 0)
		{
			subs.splice(index, 1);
		}
	}

	return {
		subscribe: subscribe,
		unsubscribe: unsubscribe
	};
}



// INCOMING PORTS


function _Platform_incomingPort(name, converter)
{
	_Platform_checkPortName(name);
	_Platform_effectManagers[name] = {
		f: _Platform_incomingPortMap,
		u: converter,
		a: _Platform_setupIncomingPort
	};
	return _Platform_leaf(name);
}


var _Platform_incomingPortMap = F2(function(tagger, finalTagger)
{
	return function(value)
	{
		return tagger(finalTagger(value));
	};
});


function _Platform_setupIncomingPort(name, sendToApp)
{
	var subs = _List_Nil;
	var converter = _Platform_effectManagers[name].u;

	// CREATE MANAGER

	var init = _Scheduler_succeed(null);

	_Platform_effectManagers[name].b = init;
	_Platform_effectManagers[name].c = F3(function(router, subList, state)
	{
		subs = subList;
		return init;
	});

	// PUBLIC API

	function send(incomingValue)
	{
		var result = A2(_Json_run, converter, _Json_wrap(incomingValue));

		$elm$core$Result$isOk(result) || _Debug_crash(4, name, result.a);

		var value = result.a;
		for (var temp = subs; temp.b; temp = temp.b) // WHILE_CONS
		{
			sendToApp(temp.a(value));
		}
	}

	return { send: send };
}



// EXPORT ELM MODULES
//
// Have DEBUG and PROD versions so that we can (1) give nicer errors in
// debug mode and (2) not pay for the bits needed for that in prod mode.
//


function _Platform_export(exports)
{
	scope['Elm']
		? _Platform_mergeExportsProd(scope['Elm'], exports)
		: scope['Elm'] = exports;
}


function _Platform_mergeExportsProd(obj, exports)
{
	for (var name in exports)
	{
		(name in obj)
			? (name == 'init')
				? _Debug_crash(6)
				: _Platform_mergeExportsProd(obj[name], exports[name])
			: (obj[name] = exports[name]);
	}
}


function _Platform_export_UNUSED(exports)
{
	scope['Elm']
		? _Platform_mergeExportsDebug('Elm', scope['Elm'], exports)
		: scope['Elm'] = exports;
}


function _Platform_mergeExportsDebug(moduleName, obj, exports)
{
	for (var name in exports)
	{
		(name in obj)
			? (name == 'init')
				? _Debug_crash(6, moduleName)
				: _Platform_mergeExportsDebug(moduleName + '.' + name, obj[name], exports[name])
			: (obj[name] = exports[name]);
	}
}




// HELPERS


var _VirtualDom_divertHrefToApp;

var _VirtualDom_doc = typeof document !== 'undefined' ? document : {};


function _VirtualDom_appendChild(parent, child)
{
	parent.appendChild(child);
}

var _VirtualDom_init = F4(function(virtualNode, flagDecoder, debugMetadata, args)
{
	// NOTE: this function needs _Platform_export available to work

	/**/
	var node = args['node'];
	//*/
	/**_UNUSED/
	var node = args && args['node'] ? args['node'] : _Debug_crash(0);
	//*/

	node.parentNode.replaceChild(
		_VirtualDom_render(virtualNode, function() {}),
		node
	);

	return {};
});



// TEXT


function _VirtualDom_text(string)
{
	return {
		$: 0,
		a: string
	};
}



// NODE


var _VirtualDom_nodeNS = F2(function(namespace, tag)
{
	return F2(function(factList, kidList)
	{
		for (var kids = [], descendantsCount = 0; kidList.b; kidList = kidList.b) // WHILE_CONS
		{
			var kid = kidList.a;
			descendantsCount += (kid.b || 0);
			kids.push(kid);
		}
		descendantsCount += kids.length;

		return {
			$: 1,
			c: tag,
			d: _VirtualDom_organizeFacts(factList),
			e: kids,
			f: namespace,
			b: descendantsCount
		};
	});
});


var _VirtualDom_node = _VirtualDom_nodeNS(undefined);



// KEYED NODE


var _VirtualDom_keyedNodeNS = F2(function(namespace, tag)
{
	return F2(function(factList, kidList)
	{
		for (var kids = [], descendantsCount = 0; kidList.b; kidList = kidList.b) // WHILE_CONS
		{
			var kid = kidList.a;
			descendantsCount += (kid.b.b || 0);
			kids.push(kid);
		}
		descendantsCount += kids.length;

		return {
			$: 2,
			c: tag,
			d: _VirtualDom_organizeFacts(factList),
			e: kids,
			f: namespace,
			b: descendantsCount
		};
	});
});


var _VirtualDom_keyedNode = _VirtualDom_keyedNodeNS(undefined);



// CUSTOM


function _VirtualDom_custom(factList, model, render, diff)
{
	return {
		$: 3,
		d: _VirtualDom_organizeFacts(factList),
		g: model,
		h: render,
		i: diff
	};
}



// MAP


var _VirtualDom_map = F2(function(tagger, node)
{
	return {
		$: 4,
		j: tagger,
		k: node,
		b: 1 + (node.b || 0)
	};
});



// LAZY


function _VirtualDom_thunk(refs, thunk)
{
	return {
		$: 5,
		l: refs,
		m: thunk,
		k: undefined
	};
}

var _VirtualDom_lazy = F2(function(func, a)
{
	return _VirtualDom_thunk([func, a], function() {
		return func(a);
	});
});

var _VirtualDom_lazy2 = F3(function(func, a, b)
{
	return _VirtualDom_thunk([func, a, b], function() {
		return A2(func, a, b);
	});
});

var _VirtualDom_lazy3 = F4(function(func, a, b, c)
{
	return _VirtualDom_thunk([func, a, b, c], function() {
		return A3(func, a, b, c);
	});
});

var _VirtualDom_lazy4 = F5(function(func, a, b, c, d)
{
	return _VirtualDom_thunk([func, a, b, c, d], function() {
		return A4(func, a, b, c, d);
	});
});

var _VirtualDom_lazy5 = F6(function(func, a, b, c, d, e)
{
	return _VirtualDom_thunk([func, a, b, c, d, e], function() {
		return A5(func, a, b, c, d, e);
	});
});

var _VirtualDom_lazy6 = F7(function(func, a, b, c, d, e, f)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f], function() {
		return A6(func, a, b, c, d, e, f);
	});
});

var _VirtualDom_lazy7 = F8(function(func, a, b, c, d, e, f, g)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f, g], function() {
		return A7(func, a, b, c, d, e, f, g);
	});
});

var _VirtualDom_lazy8 = F9(function(func, a, b, c, d, e, f, g, h)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f, g, h], function() {
		return A8(func, a, b, c, d, e, f, g, h);
	});
});



// FACTS


var _VirtualDom_on = F2(function(key, handler)
{
	return {
		$: 'a0',
		n: key,
		o: handler
	};
});
var _VirtualDom_style = F2(function(key, value)
{
	return {
		$: 'a1',
		n: key,
		o: value
	};
});
var _VirtualDom_property = F2(function(key, value)
{
	return {
		$: 'a2',
		n: key,
		o: value
	};
});
var _VirtualDom_attribute = F2(function(key, value)
{
	return {
		$: 'a3',
		n: key,
		o: value
	};
});
var _VirtualDom_attributeNS = F3(function(namespace, key, value)
{
	return {
		$: 'a4',
		n: key,
		o: { f: namespace, o: value }
	};
});



// XSS ATTACK VECTOR CHECKS


function _VirtualDom_noScript(tag)
{
	return tag == 'script' ? 'p' : tag;
}

function _VirtualDom_noOnOrFormAction(key)
{
	return /^(on|formAction$)/i.test(key) ? 'data-' + key : key;
}

function _VirtualDom_noInnerHtmlOrFormAction(key)
{
	return key == 'innerHTML' || key == 'formAction' ? 'data-' + key : key;
}

function _VirtualDom_noJavaScriptUri(value)
{
	return /^javascript:/i.test(value.replace(/\s/g,'')) ? '' : value;
}

function _VirtualDom_noJavaScriptUri_UNUSED(value)
{
	return /^javascript:/i.test(value.replace(/\s/g,''))
		? 'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'
		: value;
}

function _VirtualDom_noJavaScriptOrHtmlUri(value)
{
	return /^\s*(javascript:|data:text\/html)/i.test(value) ? '' : value;
}

function _VirtualDom_noJavaScriptOrHtmlUri_UNUSED(value)
{
	return /^\s*(javascript:|data:text\/html)/i.test(value)
		? 'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'
		: value;
}



// MAP FACTS


var _VirtualDom_mapAttribute = F2(function(func, attr)
{
	return (attr.$ === 'a0')
		? A2(_VirtualDom_on, attr.n, _VirtualDom_mapHandler(func, attr.o))
		: attr;
});

function _VirtualDom_mapHandler(func, handler)
{
	var tag = $elm$virtual_dom$VirtualDom$toHandlerInt(handler);

	// 0 = Normal
	// 1 = MayStopPropagation
	// 2 = MayPreventDefault
	// 3 = Custom

	return {
		$: handler.$,
		a:
			!tag
				? A2($elm$json$Json$Decode$map, func, handler.a)
				:
			A3($elm$json$Json$Decode$map2,
				tag < 3
					? _VirtualDom_mapEventTuple
					: _VirtualDom_mapEventRecord,
				$elm$json$Json$Decode$succeed(func),
				handler.a
			)
	};
}

var _VirtualDom_mapEventTuple = F2(function(func, tuple)
{
	return _Utils_Tuple2(func(tuple.a), tuple.b);
});

var _VirtualDom_mapEventRecord = F2(function(func, record)
{
	return {
		aA: func(record.aA),
		dK: record.dK,
		ds: record.ds
	}
});



// ORGANIZE FACTS


function _VirtualDom_organizeFacts(factList)
{
	for (var facts = {}; factList.b; factList = factList.b) // WHILE_CONS
	{
		var entry = factList.a;

		var tag = entry.$;
		var key = entry.n;
		var value = entry.o;

		if (tag === 'a2')
		{
			(key === 'className')
				? _VirtualDom_addClass(facts, key, _Json_unwrap(value))
				: facts[key] = _Json_unwrap(value);

			continue;
		}

		var subFacts = facts[tag] || (facts[tag] = {});
		(tag === 'a3' && key === 'class')
			? _VirtualDom_addClass(subFacts, key, value)
			: subFacts[key] = value;
	}

	return facts;
}

function _VirtualDom_addClass(object, key, newClass)
{
	var classes = object[key];
	object[key] = classes ? classes + ' ' + newClass : newClass;
}



// RENDER


function _VirtualDom_render(vNode, eventNode)
{
	var tag = vNode.$;

	if (tag === 5)
	{
		return _VirtualDom_render(vNode.k || (vNode.k = vNode.m()), eventNode);
	}

	if (tag === 0)
	{
		return _VirtualDom_doc.createTextNode(vNode.a);
	}

	if (tag === 4)
	{
		var subNode = vNode.k;
		var tagger = vNode.j;

		while (subNode.$ === 4)
		{
			typeof tagger !== 'object'
				? tagger = [tagger, subNode.j]
				: tagger.push(subNode.j);

			subNode = subNode.k;
		}

		var subEventRoot = { j: tagger, p: eventNode };
		var domNode = _VirtualDom_render(subNode, subEventRoot);
		domNode.elm_event_node_ref = subEventRoot;
		return domNode;
	}

	if (tag === 3)
	{
		var domNode = vNode.h(vNode.g);
		_VirtualDom_applyFacts(domNode, eventNode, vNode.d);
		return domNode;
	}

	// at this point `tag` must be 1 or 2

	var domNode = vNode.f
		? _VirtualDom_doc.createElementNS(vNode.f, vNode.c)
		: _VirtualDom_doc.createElement(vNode.c);

	if (_VirtualDom_divertHrefToApp && vNode.c == 'a')
	{
		domNode.addEventListener('click', _VirtualDom_divertHrefToApp(domNode));
	}

	_VirtualDom_applyFacts(domNode, eventNode, vNode.d);

	for (var kids = vNode.e, i = 0; i < kids.length; i++)
	{
		_VirtualDom_appendChild(domNode, _VirtualDom_render(tag === 1 ? kids[i] : kids[i].b, eventNode));
	}

	return domNode;
}



// APPLY FACTS


function _VirtualDom_applyFacts(domNode, eventNode, facts)
{
	for (var key in facts)
	{
		var value = facts[key];

		key === 'a1'
			? _VirtualDom_applyStyles(domNode, value)
			:
		key === 'a0'
			? _VirtualDom_applyEvents(domNode, eventNode, value)
			:
		key === 'a3'
			? _VirtualDom_applyAttrs(domNode, value)
			:
		key === 'a4'
			? _VirtualDom_applyAttrsNS(domNode, value)
			:
		((key !== 'value' && key !== 'checked') || domNode[key] !== value) && (domNode[key] = value);
	}
}



// APPLY STYLES


function _VirtualDom_applyStyles(domNode, styles)
{
	var domNodeStyle = domNode.style;

	for (var key in styles)
	{
		domNodeStyle[key] = styles[key];
	}
}



// APPLY ATTRS


function _VirtualDom_applyAttrs(domNode, attrs)
{
	for (var key in attrs)
	{
		var value = attrs[key];
		typeof value !== 'undefined'
			? domNode.setAttribute(key, value)
			: domNode.removeAttribute(key);
	}
}



// APPLY NAMESPACED ATTRS


function _VirtualDom_applyAttrsNS(domNode, nsAttrs)
{
	for (var key in nsAttrs)
	{
		var pair = nsAttrs[key];
		var namespace = pair.f;
		var value = pair.o;

		typeof value !== 'undefined'
			? domNode.setAttributeNS(namespace, key, value)
			: domNode.removeAttributeNS(namespace, key);
	}
}



// APPLY EVENTS


function _VirtualDom_applyEvents(domNode, eventNode, events)
{
	var allCallbacks = domNode.elmFs || (domNode.elmFs = {});

	for (var key in events)
	{
		var newHandler = events[key];
		var oldCallback = allCallbacks[key];

		if (!newHandler)
		{
			domNode.removeEventListener(key, oldCallback);
			allCallbacks[key] = undefined;
			continue;
		}

		if (oldCallback)
		{
			var oldHandler = oldCallback.q;
			if (oldHandler.$ === newHandler.$)
			{
				oldCallback.q = newHandler;
				continue;
			}
			domNode.removeEventListener(key, oldCallback);
		}

		oldCallback = _VirtualDom_makeCallback(eventNode, newHandler);
		domNode.addEventListener(key, oldCallback,
			_VirtualDom_passiveSupported
			&& { passive: $elm$virtual_dom$VirtualDom$toHandlerInt(newHandler) < 2 }
		);
		allCallbacks[key] = oldCallback;
	}
}



// PASSIVE EVENTS


var _VirtualDom_passiveSupported;

try
{
	window.addEventListener('t', null, Object.defineProperty({}, 'passive', {
		get: function() { _VirtualDom_passiveSupported = true; }
	}));
}
catch(e) {}



// EVENT HANDLERS


function _VirtualDom_makeCallback(eventNode, initialHandler)
{
	function callback(event)
	{
		var handler = callback.q;
		var result = _Json_runHelp(handler.a, event);

		if (!$elm$core$Result$isOk(result))
		{
			return;
		}

		var tag = $elm$virtual_dom$VirtualDom$toHandlerInt(handler);

		// 0 = Normal
		// 1 = MayStopPropagation
		// 2 = MayPreventDefault
		// 3 = Custom

		var value = result.a;
		var message = !tag ? value : tag < 3 ? value.a : value.aA;
		var stopPropagation = tag == 1 ? value.b : tag == 3 && value.dK;
		var currentEventNode = (
			stopPropagation && event.stopPropagation(),
			(tag == 2 ? value.b : tag == 3 && value.ds) && event.preventDefault(),
			eventNode
		);
		var tagger;
		var i;
		while (tagger = currentEventNode.j)
		{
			if (typeof tagger == 'function')
			{
				message = tagger(message);
			}
			else
			{
				for (var i = tagger.length; i--; )
				{
					message = tagger[i](message);
				}
			}
			currentEventNode = currentEventNode.p;
		}
		currentEventNode(message, stopPropagation); // stopPropagation implies isSync
	}

	callback.q = initialHandler;

	return callback;
}

function _VirtualDom_equalEvents(x, y)
{
	return x.$ == y.$ && _Json_equality(x.a, y.a);
}



// DIFF


// TODO: Should we do patches like in iOS?
//
// type Patch
//   = At Int Patch
//   | Batch (List Patch)
//   | Change ...
//
// How could it not be better?
//
function _VirtualDom_diff(x, y)
{
	var patches = [];
	_VirtualDom_diffHelp(x, y, patches, 0);
	return patches;
}


function _VirtualDom_pushPatch(patches, type, index, data)
{
	var patch = {
		$: type,
		r: index,
		s: data,
		t: undefined,
		u: undefined
	};
	patches.push(patch);
	return patch;
}


function _VirtualDom_diffHelp(x, y, patches, index)
{
	if (x === y)
	{
		return;
	}

	var xType = x.$;
	var yType = y.$;

	// Bail if you run into different types of nodes. Implies that the
	// structure has changed significantly and it's not worth a diff.
	if (xType !== yType)
	{
		if (xType === 1 && yType === 2)
		{
			y = _VirtualDom_dekey(y);
			yType = 1;
		}
		else
		{
			_VirtualDom_pushPatch(patches, 0, index, y);
			return;
		}
	}

	// Now we know that both nodes are the same $.
	switch (yType)
	{
		case 5:
			var xRefs = x.l;
			var yRefs = y.l;
			var i = xRefs.length;
			var same = i === yRefs.length;
			while (same && i--)
			{
				same = xRefs[i] === yRefs[i];
			}
			if (same)
			{
				y.k = x.k;
				return;
			}
			y.k = y.m();
			var subPatches = [];
			_VirtualDom_diffHelp(x.k, y.k, subPatches, 0);
			subPatches.length > 0 && _VirtualDom_pushPatch(patches, 1, index, subPatches);
			return;

		case 4:
			// gather nested taggers
			var xTaggers = x.j;
			var yTaggers = y.j;
			var nesting = false;

			var xSubNode = x.k;
			while (xSubNode.$ === 4)
			{
				nesting = true;

				typeof xTaggers !== 'object'
					? xTaggers = [xTaggers, xSubNode.j]
					: xTaggers.push(xSubNode.j);

				xSubNode = xSubNode.k;
			}

			var ySubNode = y.k;
			while (ySubNode.$ === 4)
			{
				nesting = true;

				typeof yTaggers !== 'object'
					? yTaggers = [yTaggers, ySubNode.j]
					: yTaggers.push(ySubNode.j);

				ySubNode = ySubNode.k;
			}

			// Just bail if different numbers of taggers. This implies the
			// structure of the virtual DOM has changed.
			if (nesting && xTaggers.length !== yTaggers.length)
			{
				_VirtualDom_pushPatch(patches, 0, index, y);
				return;
			}

			// check if taggers are "the same"
			if (nesting ? !_VirtualDom_pairwiseRefEqual(xTaggers, yTaggers) : xTaggers !== yTaggers)
			{
				_VirtualDom_pushPatch(patches, 2, index, yTaggers);
			}

			// diff everything below the taggers
			_VirtualDom_diffHelp(xSubNode, ySubNode, patches, index + 1);
			return;

		case 0:
			if (x.a !== y.a)
			{
				_VirtualDom_pushPatch(patches, 3, index, y.a);
			}
			return;

		case 1:
			_VirtualDom_diffNodes(x, y, patches, index, _VirtualDom_diffKids);
			return;

		case 2:
			_VirtualDom_diffNodes(x, y, patches, index, _VirtualDom_diffKeyedKids);
			return;

		case 3:
			if (x.h !== y.h)
			{
				_VirtualDom_pushPatch(patches, 0, index, y);
				return;
			}

			var factsDiff = _VirtualDom_diffFacts(x.d, y.d);
			factsDiff && _VirtualDom_pushPatch(patches, 4, index, factsDiff);

			var patch = y.i(x.g, y.g);
			patch && _VirtualDom_pushPatch(patches, 5, index, patch);

			return;
	}
}

// assumes the incoming arrays are the same length
function _VirtualDom_pairwiseRefEqual(as, bs)
{
	for (var i = 0; i < as.length; i++)
	{
		if (as[i] !== bs[i])
		{
			return false;
		}
	}

	return true;
}

function _VirtualDom_diffNodes(x, y, patches, index, diffKids)
{
	// Bail if obvious indicators have changed. Implies more serious
	// structural changes such that it's not worth it to diff.
	if (x.c !== y.c || x.f !== y.f)
	{
		_VirtualDom_pushPatch(patches, 0, index, y);
		return;
	}

	var factsDiff = _VirtualDom_diffFacts(x.d, y.d);
	factsDiff && _VirtualDom_pushPatch(patches, 4, index, factsDiff);

	diffKids(x, y, patches, index);
}



// DIFF FACTS


// TODO Instead of creating a new diff object, it's possible to just test if
// there *is* a diff. During the actual patch, do the diff again and make the
// modifications directly. This way, there's no new allocations. Worth it?
function _VirtualDom_diffFacts(x, y, category)
{
	var diff;

	// look for changes and removals
	for (var xKey in x)
	{
		if (xKey === 'a1' || xKey === 'a0' || xKey === 'a3' || xKey === 'a4')
		{
			var subDiff = _VirtualDom_diffFacts(x[xKey], y[xKey] || {}, xKey);
			if (subDiff)
			{
				diff = diff || {};
				diff[xKey] = subDiff;
			}
			continue;
		}

		// remove if not in the new facts
		if (!(xKey in y))
		{
			diff = diff || {};
			diff[xKey] =
				!category
					? (typeof x[xKey] === 'string' ? '' : null)
					:
				(category === 'a1')
					? ''
					:
				(category === 'a0' || category === 'a3')
					? undefined
					:
				{ f: x[xKey].f, o: undefined };

			continue;
		}

		var xValue = x[xKey];
		var yValue = y[xKey];

		// reference equal, so don't worry about it
		if (xValue === yValue && xKey !== 'value' && xKey !== 'checked'
			|| category === 'a0' && _VirtualDom_equalEvents(xValue, yValue))
		{
			continue;
		}

		diff = diff || {};
		diff[xKey] = yValue;
	}

	// add new stuff
	for (var yKey in y)
	{
		if (!(yKey in x))
		{
			diff = diff || {};
			diff[yKey] = y[yKey];
		}
	}

	return diff;
}



// DIFF KIDS


function _VirtualDom_diffKids(xParent, yParent, patches, index)
{
	var xKids = xParent.e;
	var yKids = yParent.e;

	var xLen = xKids.length;
	var yLen = yKids.length;

	// FIGURE OUT IF THERE ARE INSERTS OR REMOVALS

	if (xLen > yLen)
	{
		_VirtualDom_pushPatch(patches, 6, index, {
			v: yLen,
			i: xLen - yLen
		});
	}
	else if (xLen < yLen)
	{
		_VirtualDom_pushPatch(patches, 7, index, {
			v: xLen,
			e: yKids
		});
	}

	// PAIRWISE DIFF EVERYTHING ELSE

	for (var minLen = xLen < yLen ? xLen : yLen, i = 0; i < minLen; i++)
	{
		var xKid = xKids[i];
		_VirtualDom_diffHelp(xKid, yKids[i], patches, ++index);
		index += xKid.b || 0;
	}
}



// KEYED DIFF


function _VirtualDom_diffKeyedKids(xParent, yParent, patches, rootIndex)
{
	var localPatches = [];

	var changes = {}; // Dict String Entry
	var inserts = []; // Array { index : Int, entry : Entry }
	// type Entry = { tag : String, vnode : VNode, index : Int, data : _ }

	var xKids = xParent.e;
	var yKids = yParent.e;
	var xLen = xKids.length;
	var yLen = yKids.length;
	var xIndex = 0;
	var yIndex = 0;

	var index = rootIndex;

	while (xIndex < xLen && yIndex < yLen)
	{
		var x = xKids[xIndex];
		var y = yKids[yIndex];

		var xKey = x.a;
		var yKey = y.a;
		var xNode = x.b;
		var yNode = y.b;

		var newMatch = undefined;
		var oldMatch = undefined;

		// check if keys match

		if (xKey === yKey)
		{
			index++;
			_VirtualDom_diffHelp(xNode, yNode, localPatches, index);
			index += xNode.b || 0;

			xIndex++;
			yIndex++;
			continue;
		}

		// look ahead 1 to detect insertions and removals.

		var xNext = xKids[xIndex + 1];
		var yNext = yKids[yIndex + 1];

		if (xNext)
		{
			var xNextKey = xNext.a;
			var xNextNode = xNext.b;
			oldMatch = yKey === xNextKey;
		}

		if (yNext)
		{
			var yNextKey = yNext.a;
			var yNextNode = yNext.b;
			newMatch = xKey === yNextKey;
		}


		// swap x and y
		if (newMatch && oldMatch)
		{
			index++;
			_VirtualDom_diffHelp(xNode, yNextNode, localPatches, index);
			_VirtualDom_insertNode(changes, localPatches, xKey, yNode, yIndex, inserts);
			index += xNode.b || 0;

			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNextNode, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 2;
			continue;
		}

		// insert y
		if (newMatch)
		{
			index++;
			_VirtualDom_insertNode(changes, localPatches, yKey, yNode, yIndex, inserts);
			_VirtualDom_diffHelp(xNode, yNextNode, localPatches, index);
			index += xNode.b || 0;

			xIndex += 1;
			yIndex += 2;
			continue;
		}

		// remove x
		if (oldMatch)
		{
			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNode, index);
			index += xNode.b || 0;

			index++;
			_VirtualDom_diffHelp(xNextNode, yNode, localPatches, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 1;
			continue;
		}

		// remove x, insert y
		if (xNext && xNextKey === yNextKey)
		{
			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNode, index);
			_VirtualDom_insertNode(changes, localPatches, yKey, yNode, yIndex, inserts);
			index += xNode.b || 0;

			index++;
			_VirtualDom_diffHelp(xNextNode, yNextNode, localPatches, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 2;
			continue;
		}

		break;
	}

	// eat up any remaining nodes with removeNode and insertNode

	while (xIndex < xLen)
	{
		index++;
		var x = xKids[xIndex];
		var xNode = x.b;
		_VirtualDom_removeNode(changes, localPatches, x.a, xNode, index);
		index += xNode.b || 0;
		xIndex++;
	}

	while (yIndex < yLen)
	{
		var endInserts = endInserts || [];
		var y = yKids[yIndex];
		_VirtualDom_insertNode(changes, localPatches, y.a, y.b, undefined, endInserts);
		yIndex++;
	}

	if (localPatches.length > 0 || inserts.length > 0 || endInserts)
	{
		_VirtualDom_pushPatch(patches, 8, rootIndex, {
			w: localPatches,
			x: inserts,
			y: endInserts
		});
	}
}



// CHANGES FROM KEYED DIFF


var _VirtualDom_POSTFIX = '_elmW6BL';


function _VirtualDom_insertNode(changes, localPatches, key, vnode, yIndex, inserts)
{
	var entry = changes[key];

	// never seen this key before
	if (!entry)
	{
		entry = {
			c: 0,
			z: vnode,
			r: yIndex,
			s: undefined
		};

		inserts.push({ r: yIndex, A: entry });
		changes[key] = entry;

		return;
	}

	// this key was removed earlier, a match!
	if (entry.c === 1)
	{
		inserts.push({ r: yIndex, A: entry });

		entry.c = 2;
		var subPatches = [];
		_VirtualDom_diffHelp(entry.z, vnode, subPatches, entry.r);
		entry.r = yIndex;
		entry.s.s = {
			w: subPatches,
			A: entry
		};

		return;
	}

	// this key has already been inserted or moved, a duplicate!
	_VirtualDom_insertNode(changes, localPatches, key + _VirtualDom_POSTFIX, vnode, yIndex, inserts);
}


function _VirtualDom_removeNode(changes, localPatches, key, vnode, index)
{
	var entry = changes[key];

	// never seen this key before
	if (!entry)
	{
		var patch = _VirtualDom_pushPatch(localPatches, 9, index, undefined);

		changes[key] = {
			c: 1,
			z: vnode,
			r: index,
			s: patch
		};

		return;
	}

	// this key was inserted earlier, a match!
	if (entry.c === 0)
	{
		entry.c = 2;
		var subPatches = [];
		_VirtualDom_diffHelp(vnode, entry.z, subPatches, index);

		_VirtualDom_pushPatch(localPatches, 9, index, {
			w: subPatches,
			A: entry
		});

		return;
	}

	// this key has already been removed or moved, a duplicate!
	_VirtualDom_removeNode(changes, localPatches, key + _VirtualDom_POSTFIX, vnode, index);
}



// ADD DOM NODES
//
// Each DOM node has an "index" assigned in order of traversal. It is important
// to minimize our crawl over the actual DOM, so these indexes (along with the
// descendantsCount of virtual nodes) let us skip touching entire subtrees of
// the DOM if we know there are no patches there.


function _VirtualDom_addDomNodes(domNode, vNode, patches, eventNode)
{
	_VirtualDom_addDomNodesHelp(domNode, vNode, patches, 0, 0, vNode.b, eventNode);
}


// assumes `patches` is non-empty and indexes increase monotonically.
function _VirtualDom_addDomNodesHelp(domNode, vNode, patches, i, low, high, eventNode)
{
	var patch = patches[i];
	var index = patch.r;

	while (index === low)
	{
		var patchType = patch.$;

		if (patchType === 1)
		{
			_VirtualDom_addDomNodes(domNode, vNode.k, patch.s, eventNode);
		}
		else if (patchType === 8)
		{
			patch.t = domNode;
			patch.u = eventNode;

			var subPatches = patch.s.w;
			if (subPatches.length > 0)
			{
				_VirtualDom_addDomNodesHelp(domNode, vNode, subPatches, 0, low, high, eventNode);
			}
		}
		else if (patchType === 9)
		{
			patch.t = domNode;
			patch.u = eventNode;

			var data = patch.s;
			if (data)
			{
				data.A.s = domNode;
				var subPatches = data.w;
				if (subPatches.length > 0)
				{
					_VirtualDom_addDomNodesHelp(domNode, vNode, subPatches, 0, low, high, eventNode);
				}
			}
		}
		else
		{
			patch.t = domNode;
			patch.u = eventNode;
		}

		i++;

		if (!(patch = patches[i]) || (index = patch.r) > high)
		{
			return i;
		}
	}

	var tag = vNode.$;

	if (tag === 4)
	{
		var subNode = vNode.k;

		while (subNode.$ === 4)
		{
			subNode = subNode.k;
		}

		return _VirtualDom_addDomNodesHelp(domNode, subNode, patches, i, low + 1, high, domNode.elm_event_node_ref);
	}

	// tag must be 1 or 2 at this point

	var vKids = vNode.e;
	var childNodes = domNode.childNodes;
	for (var j = 0; j < vKids.length; j++)
	{
		low++;
		var vKid = tag === 1 ? vKids[j] : vKids[j].b;
		var nextLow = low + (vKid.b || 0);
		if (low <= index && index <= nextLow)
		{
			i = _VirtualDom_addDomNodesHelp(childNodes[j], vKid, patches, i, low, nextLow, eventNode);
			if (!(patch = patches[i]) || (index = patch.r) > high)
			{
				return i;
			}
		}
		low = nextLow;
	}
	return i;
}



// APPLY PATCHES


function _VirtualDom_applyPatches(rootDomNode, oldVirtualNode, patches, eventNode)
{
	if (patches.length === 0)
	{
		return rootDomNode;
	}

	_VirtualDom_addDomNodes(rootDomNode, oldVirtualNode, patches, eventNode);
	return _VirtualDom_applyPatchesHelp(rootDomNode, patches);
}

function _VirtualDom_applyPatchesHelp(rootDomNode, patches)
{
	for (var i = 0; i < patches.length; i++)
	{
		var patch = patches[i];
		var localDomNode = patch.t
		var newNode = _VirtualDom_applyPatch(localDomNode, patch);
		if (localDomNode === rootDomNode)
		{
			rootDomNode = newNode;
		}
	}
	return rootDomNode;
}

function _VirtualDom_applyPatch(domNode, patch)
{
	switch (patch.$)
	{
		case 0:
			return _VirtualDom_applyPatchRedraw(domNode, patch.s, patch.u);

		case 4:
			_VirtualDom_applyFacts(domNode, patch.u, patch.s);
			return domNode;

		case 3:
			domNode.replaceData(0, domNode.length, patch.s);
			return domNode;

		case 1:
			return _VirtualDom_applyPatchesHelp(domNode, patch.s);

		case 2:
			if (domNode.elm_event_node_ref)
			{
				domNode.elm_event_node_ref.j = patch.s;
			}
			else
			{
				domNode.elm_event_node_ref = { j: patch.s, p: patch.u };
			}
			return domNode;

		case 6:
			var data = patch.s;
			for (var i = 0; i < data.i; i++)
			{
				domNode.removeChild(domNode.childNodes[data.v]);
			}
			return domNode;

		case 7:
			var data = patch.s;
			var kids = data.e;
			var i = data.v;
			var theEnd = domNode.childNodes[i];
			for (; i < kids.length; i++)
			{
				domNode.insertBefore(_VirtualDom_render(kids[i], patch.u), theEnd);
			}
			return domNode;

		case 9:
			var data = patch.s;
			if (!data)
			{
				domNode.parentNode.removeChild(domNode);
				return domNode;
			}
			var entry = data.A;
			if (typeof entry.r !== 'undefined')
			{
				domNode.parentNode.removeChild(domNode);
			}
			entry.s = _VirtualDom_applyPatchesHelp(domNode, data.w);
			return domNode;

		case 8:
			return _VirtualDom_applyPatchReorder(domNode, patch);

		case 5:
			return patch.s(domNode);

		default:
			_Debug_crash(10); // 'Ran into an unknown patch!'
	}
}


function _VirtualDom_applyPatchRedraw(domNode, vNode, eventNode)
{
	var parentNode = domNode.parentNode;
	var newNode = _VirtualDom_render(vNode, eventNode);

	if (!newNode.elm_event_node_ref)
	{
		newNode.elm_event_node_ref = domNode.elm_event_node_ref;
	}

	if (parentNode && newNode !== domNode)
	{
		parentNode.replaceChild(newNode, domNode);
	}
	return newNode;
}


function _VirtualDom_applyPatchReorder(domNode, patch)
{
	var data = patch.s;

	// remove end inserts
	var frag = _VirtualDom_applyPatchReorderEndInsertsHelp(data.y, patch);

	// removals
	domNode = _VirtualDom_applyPatchesHelp(domNode, data.w);

	// inserts
	var inserts = data.x;
	for (var i = 0; i < inserts.length; i++)
	{
		var insert = inserts[i];
		var entry = insert.A;
		var node = entry.c === 2
			? entry.s
			: _VirtualDom_render(entry.z, patch.u);
		domNode.insertBefore(node, domNode.childNodes[insert.r]);
	}

	// add end inserts
	if (frag)
	{
		_VirtualDom_appendChild(domNode, frag);
	}

	return domNode;
}


function _VirtualDom_applyPatchReorderEndInsertsHelp(endInserts, patch)
{
	if (!endInserts)
	{
		return;
	}

	var frag = _VirtualDom_doc.createDocumentFragment();
	for (var i = 0; i < endInserts.length; i++)
	{
		var insert = endInserts[i];
		var entry = insert.A;
		_VirtualDom_appendChild(frag, entry.c === 2
			? entry.s
			: _VirtualDom_render(entry.z, patch.u)
		);
	}
	return frag;
}


function _VirtualDom_virtualize(node)
{
	// TEXT NODES

	if (node.nodeType === 3)
	{
		return _VirtualDom_text(node.textContent);
	}


	// WEIRD NODES

	if (node.nodeType !== 1)
	{
		return _VirtualDom_text('');
	}


	// ELEMENT NODES

	var attrList = _List_Nil;
	var attrs = node.attributes;
	for (var i = attrs.length; i--; )
	{
		var attr = attrs[i];
		var name = attr.name;
		var value = attr.value;
		attrList = _List_Cons( A2(_VirtualDom_attribute, name, value), attrList );
	}

	var tag = node.tagName.toLowerCase();
	var kidList = _List_Nil;
	var kids = node.childNodes;

	for (var i = kids.length; i--; )
	{
		kidList = _List_Cons(_VirtualDom_virtualize(kids[i]), kidList);
	}
	return A3(_VirtualDom_node, tag, attrList, kidList);
}

function _VirtualDom_dekey(keyedNode)
{
	var keyedKids = keyedNode.e;
	var len = keyedKids.length;
	var kids = new Array(len);
	for (var i = 0; i < len; i++)
	{
		kids[i] = keyedKids[i].b;
	}

	return {
		$: 1,
		c: keyedNode.c,
		d: keyedNode.d,
		e: kids,
		f: keyedNode.f,
		b: keyedNode.b
	};
}




// ELEMENT


var _Debugger_element;

var _Browser_element = _Debugger_element || F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.gK,
		impl.h8,
		impl.hK,
		function(sendToApp, initialModel) {
			var view = impl.bq;
			/**/
			var domNode = args['node'];
			//*/
			/**_UNUSED/
			var domNode = args && args['node'] ? args['node'] : _Debug_crash(0);
			//*/
			var currNode = _VirtualDom_virtualize(domNode);

			return _Browser_makeAnimator(initialModel, function(model)
			{
				var nextNode = view(model);
				var patches = _VirtualDom_diff(currNode, nextNode);
				domNode = _VirtualDom_applyPatches(domNode, currNode, patches, sendToApp);
				currNode = nextNode;
			});
		}
	);
});



// DOCUMENT


var _Debugger_document;

var _Browser_document = _Debugger_document || F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.gK,
		impl.h8,
		impl.hK,
		function(sendToApp, initialModel) {
			var divertHrefToApp = impl.dB && impl.dB(sendToApp)
			var view = impl.bq;
			var title = _VirtualDom_doc.title;
			var bodyNode = _VirtualDom_doc.body;
			var currNode = _VirtualDom_virtualize(bodyNode);
			return _Browser_makeAnimator(initialModel, function(model)
			{
				_VirtualDom_divertHrefToApp = divertHrefToApp;
				var doc = view(model);
				var nextNode = _VirtualDom_node('body')(_List_Nil)(doc.cC);
				var patches = _VirtualDom_diff(currNode, nextNode);
				bodyNode = _VirtualDom_applyPatches(bodyNode, currNode, patches, sendToApp);
				currNode = nextNode;
				_VirtualDom_divertHrefToApp = 0;
				(title !== doc.dO) && (_VirtualDom_doc.title = title = doc.dO);
			});
		}
	);
});



// ANIMATION


var _Browser_cancelAnimationFrame =
	typeof cancelAnimationFrame !== 'undefined'
		? cancelAnimationFrame
		: function(id) { clearTimeout(id); };

var _Browser_requestAnimationFrame =
	typeof requestAnimationFrame !== 'undefined'
		? requestAnimationFrame
		: function(callback) { return setTimeout(callback, 1000 / 60); };


function _Browser_makeAnimator(model, draw)
{
	draw(model);

	var state = 0;

	function updateIfNeeded()
	{
		state = state === 1
			? 0
			: ( _Browser_requestAnimationFrame(updateIfNeeded), draw(model), 1 );
	}

	return function(nextModel, isSync)
	{
		model = nextModel;

		isSync
			? ( draw(model),
				state === 2 && (state = 1)
				)
			: ( state === 0 && _Browser_requestAnimationFrame(updateIfNeeded),
				state = 2
				);
	};
}



// APPLICATION


function _Browser_application(impl)
{
	var onUrlChange = impl.g5;
	var onUrlRequest = impl.g6;
	var key = function() { key.a(onUrlChange(_Browser_getUrl())); };

	return _Browser_document({
		dB: function(sendToApp)
		{
			key.a = sendToApp;
			_Browser_window.addEventListener('popstate', key);
			_Browser_window.navigator.userAgent.indexOf('Trident') < 0 || _Browser_window.addEventListener('hashchange', key);

			return F2(function(domNode, event)
			{
				if (!event.ctrlKey && !event.metaKey && !event.shiftKey && event.button < 1 && !domNode.target && !domNode.hasAttribute('download'))
				{
					event.preventDefault();
					var href = domNode.href;
					var curr = _Browser_getUrl();
					var next = $elm$url$Url$fromString(href).a;
					sendToApp(onUrlRequest(
						(next
							&& curr.e9 === next.e9
							&& curr.ex === next.ex
							&& curr.e5.a === next.e5.a
						)
							? $elm$browser$Browser$Internal(next)
							: $elm$browser$Browser$External(href)
					));
				}
			});
		},
		gK: function(flags)
		{
			return A3(impl.gK, flags, _Browser_getUrl(), key);
		},
		bq: impl.bq,
		h8: impl.h8,
		hK: impl.hK
	});
}

function _Browser_getUrl()
{
	return $elm$url$Url$fromString(_VirtualDom_doc.location.href).a || _Debug_crash(1);
}

var _Browser_go = F2(function(key, n)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		n && history.go(n);
		key();
	}));
});

var _Browser_pushUrl = F2(function(key, url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		history.pushState({}, '', url);
		key();
	}));
});

var _Browser_replaceUrl = F2(function(key, url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		history.replaceState({}, '', url);
		key();
	}));
});



// GLOBAL EVENTS


var _Browser_fakeNode = { addEventListener: function() {}, removeEventListener: function() {} };
var _Browser_doc = typeof document !== 'undefined' ? document : _Browser_fakeNode;
var _Browser_window = typeof window !== 'undefined' ? window : _Browser_fakeNode;

var _Browser_on = F3(function(node, eventName, sendToSelf)
{
	return _Scheduler_spawn(_Scheduler_binding(function(callback)
	{
		function handler(event)	{ _Scheduler_rawSpawn(sendToSelf(event)); }
		node.addEventListener(eventName, handler, _VirtualDom_passiveSupported && { passive: true });
		return function() { node.removeEventListener(eventName, handler); };
	}));
});

var _Browser_decodeEvent = F2(function(decoder, event)
{
	var result = _Json_runHelp(decoder, event);
	return $elm$core$Result$isOk(result) ? $elm$core$Maybe$Just(result.a) : $elm$core$Maybe$Nothing;
});



// PAGE VISIBILITY


function _Browser_visibilityInfo()
{
	return (typeof _VirtualDom_doc.hidden !== 'undefined')
		? { gC: 'hidden', f9: 'visibilitychange' }
		:
	(typeof _VirtualDom_doc.mozHidden !== 'undefined')
		? { gC: 'mozHidden', f9: 'mozvisibilitychange' }
		:
	(typeof _VirtualDom_doc.msHidden !== 'undefined')
		? { gC: 'msHidden', f9: 'msvisibilitychange' }
		:
	(typeof _VirtualDom_doc.webkitHidden !== 'undefined')
		? { gC: 'webkitHidden', f9: 'webkitvisibilitychange' }
		: { gC: 'hidden', f9: 'visibilitychange' };
}



// ANIMATION FRAMES


function _Browser_rAF()
{
	return _Scheduler_binding(function(callback)
	{
		var id = _Browser_requestAnimationFrame(function() {
			callback(_Scheduler_succeed(Date.now()));
		});

		return function() {
			_Browser_cancelAnimationFrame(id);
		};
	});
}


function _Browser_now()
{
	return _Scheduler_binding(function(callback)
	{
		callback(_Scheduler_succeed(Date.now()));
	});
}



// DOM STUFF


function _Browser_withNode(id, doStuff)
{
	return _Scheduler_binding(function(callback)
	{
		_Browser_requestAnimationFrame(function() {
			var node = document.getElementById(id);
			callback(node
				? _Scheduler_succeed(doStuff(node))
				: _Scheduler_fail($elm$browser$Browser$Dom$NotFound(id))
			);
		});
	});
}


function _Browser_withWindow(doStuff)
{
	return _Scheduler_binding(function(callback)
	{
		_Browser_requestAnimationFrame(function() {
			callback(_Scheduler_succeed(doStuff()));
		});
	});
}


// FOCUS and BLUR


var _Browser_call = F2(function(functionName, id)
{
	return _Browser_withNode(id, function(node) {
		node[functionName]();
		return _Utils_Tuple0;
	});
});



// WINDOW VIEWPORT


function _Browser_getViewport()
{
	return {
		fj: _Browser_getScene(),
		fB: {
			dZ: _Browser_window.pageXOffset,
			d0: _Browser_window.pageYOffset,
			aL: _Browser_doc.documentElement.clientWidth,
			cO: _Browser_doc.documentElement.clientHeight
		}
	};
}

function _Browser_getScene()
{
	var body = _Browser_doc.body;
	var elem = _Browser_doc.documentElement;
	return {
		aL: Math.max(body.scrollWidth, body.offsetWidth, elem.scrollWidth, elem.offsetWidth, elem.clientWidth),
		cO: Math.max(body.scrollHeight, body.offsetHeight, elem.scrollHeight, elem.offsetHeight, elem.clientHeight)
	};
}

var _Browser_setViewport = F2(function(x, y)
{
	return _Browser_withWindow(function()
	{
		_Browser_window.scroll(x, y);
		return _Utils_Tuple0;
	});
});



// ELEMENT VIEWPORT


function _Browser_getViewportOf(id)
{
	return _Browser_withNode(id, function(node)
	{
		return {
			fj: {
				aL: node.scrollWidth,
				cO: node.scrollHeight
			},
			fB: {
				dZ: node.scrollLeft,
				d0: node.scrollTop,
				aL: node.clientWidth,
				cO: node.clientHeight
			}
		};
	});
}


var _Browser_setViewportOf = F3(function(id, x, y)
{
	return _Browser_withNode(id, function(node)
	{
		node.scrollLeft = x;
		node.scrollTop = y;
		return _Utils_Tuple0;
	});
});



// ELEMENT


function _Browser_getElement(id)
{
	return _Browser_withNode(id, function(node)
	{
		var rect = node.getBoundingClientRect();
		var x = _Browser_window.pageXOffset;
		var y = _Browser_window.pageYOffset;
		return {
			fj: _Browser_getScene(),
			fB: {
				dZ: x,
				d0: y,
				aL: _Browser_doc.documentElement.clientWidth,
				cO: _Browser_doc.documentElement.clientHeight
			},
			gp: {
				dZ: x + rect.left,
				d0: y + rect.top,
				aL: rect.width,
				cO: rect.height
			}
		};
	});
}



// LOAD and RELOAD


function _Browser_reload(skipCache)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function(callback)
	{
		_VirtualDom_doc.location.reload(skipCache);
	}));
}

function _Browser_load(url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function(callback)
	{
		try
		{
			_Browser_window.location = url;
		}
		catch(err)
		{
			// Only Firefox can throw a NS_ERROR_MALFORMED_URI exception here.
			// Other browsers reload the page, so let's be consistent about that.
			_VirtualDom_doc.location.reload(false);
		}
	}));
}



// DECODER

var _File_decoder = _Json_decodePrim(function(value) {
	// NOTE: checks if `File` exists in case this is run on node
	return (typeof File !== 'undefined' && value instanceof File)
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a FILE', value);
});


// METADATA

function _File_name(file) { return file.name; }
function _File_mime(file) { return file.type; }
function _File_size(file) { return file.size; }

function _File_lastModified(file)
{
	return $elm$time$Time$millisToPosix(file.lastModified);
}


// DOWNLOAD

var _File_downloadNode;

function _File_getDownloadNode()
{
	return _File_downloadNode || (_File_downloadNode = document.createElement('a'));
}

var _File_download = F3(function(name, mime, content)
{
	return _Scheduler_binding(function(callback)
	{
		var blob = new Blob([content], {type: mime});

		// for IE10+
		if (navigator.msSaveOrOpenBlob)
		{
			navigator.msSaveOrOpenBlob(blob, name);
			return;
		}

		// for HTML5
		var node = _File_getDownloadNode();
		var objectUrl = URL.createObjectURL(blob);
		node.href = objectUrl;
		node.download = name;
		_File_click(node);
		URL.revokeObjectURL(objectUrl);
	});
});

function _File_downloadUrl(href)
{
	return _Scheduler_binding(function(callback)
	{
		var node = _File_getDownloadNode();
		node.href = href;
		node.download = '';
		node.origin === location.origin || (node.target = '_blank');
		_File_click(node);
	});
}


// IE COMPATIBILITY

function _File_makeBytesSafeForInternetExplorer(bytes)
{
	// only needed by IE10 and IE11 to fix https://github.com/elm/file/issues/10
	// all other browsers can just run `new Blob([bytes])` directly with no problem
	//
	return new Uint8Array(bytes.buffer, bytes.byteOffset, bytes.byteLength);
}

function _File_click(node)
{
	// only needed by IE10 and IE11 to fix https://github.com/elm/file/issues/11
	// all other browsers have MouseEvent and do not need this conditional stuff
	//
	if (typeof MouseEvent === 'function')
	{
		node.dispatchEvent(new MouseEvent('click'));
	}
	else
	{
		var event = document.createEvent('MouseEvents');
		event.initMouseEvent('click', true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
		document.body.appendChild(node);
		node.dispatchEvent(event);
		document.body.removeChild(node);
	}
}


// UPLOAD

var _File_node;

function _File_uploadOne(mimes)
{
	return _Scheduler_binding(function(callback)
	{
		_File_node = document.createElement('input');
		_File_node.type = 'file';
		_File_node.accept = A2($elm$core$String$join, ',', mimes);
		_File_node.addEventListener('change', function(event)
		{
			callback(_Scheduler_succeed(event.target.files[0]));
		});
		_File_click(_File_node);
	});
}

function _File_uploadOneOrMore(mimes)
{
	return _Scheduler_binding(function(callback)
	{
		_File_node = document.createElement('input');
		_File_node.type = 'file';
		_File_node.multiple = true;
		_File_node.accept = A2($elm$core$String$join, ',', mimes);
		_File_node.addEventListener('change', function(event)
		{
			var elmFiles = _List_fromArray(event.target.files);
			callback(_Scheduler_succeed(_Utils_Tuple2(elmFiles.a, elmFiles.b)));
		});
		_File_click(_File_node);
	});
}


// CONTENT

function _File_toString(blob)
{
	return _Scheduler_binding(function(callback)
	{
		var reader = new FileReader();
		reader.addEventListener('loadend', function() {
			callback(_Scheduler_succeed(reader.result));
		});
		reader.readAsText(blob);
		return function() { reader.abort(); };
	});
}

function _File_toBytes(blob)
{
	return _Scheduler_binding(function(callback)
	{
		var reader = new FileReader();
		reader.addEventListener('loadend', function() {
			callback(_Scheduler_succeed(new DataView(reader.result)));
		});
		reader.readAsArrayBuffer(blob);
		return function() { reader.abort(); };
	});
}

function _File_toUrl(blob)
{
	return _Scheduler_binding(function(callback)
	{
		var reader = new FileReader();
		reader.addEventListener('loadend', function() {
			callback(_Scheduler_succeed(reader.result));
		});
		reader.readAsDataURL(blob);
		return function() { reader.abort(); };
	});
}




var _Bitwise_and = F2(function(a, b)
{
	return a & b;
});

var _Bitwise_or = F2(function(a, b)
{
	return a | b;
});

var _Bitwise_xor = F2(function(a, b)
{
	return a ^ b;
});

function _Bitwise_complement(a)
{
	return ~a;
};

var _Bitwise_shiftLeftBy = F2(function(offset, a)
{
	return a << offset;
});

var _Bitwise_shiftRightBy = F2(function(offset, a)
{
	return a >> offset;
});

var _Bitwise_shiftRightZfBy = F2(function(offset, a)
{
	return a >>> offset;
});
var $author$project$Main$LinkClicked = function (a) {
	return {$: 0, a: a};
};
var $author$project$Main$UrlChanged = function (a) {
	return {$: 1, a: a};
};
var $elm$core$Basics$EQ = 1;
var $elm$core$Basics$GT = 2;
var $elm$core$Basics$LT = 0;
var $elm$core$List$cons = _List_cons;
var $elm$core$Dict$foldr = F3(
	function (func, acc, t) {
		foldr:
		while (true) {
			if (t.$ === -2) {
				return acc;
			} else {
				var key = t.b;
				var value = t.c;
				var left = t.d;
				var right = t.e;
				var $temp$func = func,
					$temp$acc = A3(
					func,
					key,
					value,
					A3($elm$core$Dict$foldr, func, acc, right)),
					$temp$t = left;
				func = $temp$func;
				acc = $temp$acc;
				t = $temp$t;
				continue foldr;
			}
		}
	});
var $elm$core$Dict$toList = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, list) {
				return A2(
					$elm$core$List$cons,
					_Utils_Tuple2(key, value),
					list);
			}),
		_List_Nil,
		dict);
};
var $elm$core$Dict$keys = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, keyList) {
				return A2($elm$core$List$cons, key, keyList);
			}),
		_List_Nil,
		dict);
};
var $elm$core$Set$toList = function (_v0) {
	var dict = _v0;
	return $elm$core$Dict$keys(dict);
};
var $elm$core$Elm$JsArray$foldr = _JsArray_foldr;
var $elm$core$Array$foldr = F3(
	function (func, baseCase, _v0) {
		var tree = _v0.c;
		var tail = _v0.d;
		var helper = F2(
			function (node, acc) {
				if (!node.$) {
					var subTree = node.a;
					return A3($elm$core$Elm$JsArray$foldr, helper, acc, subTree);
				} else {
					var values = node.a;
					return A3($elm$core$Elm$JsArray$foldr, func, acc, values);
				}
			});
		return A3(
			$elm$core$Elm$JsArray$foldr,
			helper,
			A3($elm$core$Elm$JsArray$foldr, func, baseCase, tail),
			tree);
	});
var $elm$core$Array$toList = function (array) {
	return A3($elm$core$Array$foldr, $elm$core$List$cons, _List_Nil, array);
};
var $elm$core$Result$Err = function (a) {
	return {$: 1, a: a};
};
var $elm$json$Json$Decode$Failure = F2(
	function (a, b) {
		return {$: 3, a: a, b: b};
	});
var $elm$json$Json$Decode$Field = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $elm$json$Json$Decode$Index = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $elm$core$Result$Ok = function (a) {
	return {$: 0, a: a};
};
var $elm$json$Json$Decode$OneOf = function (a) {
	return {$: 2, a: a};
};
var $elm$core$Basics$False = 1;
var $elm$core$Basics$add = _Basics_add;
var $elm$core$Maybe$Just = function (a) {
	return {$: 0, a: a};
};
var $elm$core$Maybe$Nothing = {$: 1};
var $elm$core$String$all = _String_all;
var $elm$core$Basics$and = _Basics_and;
var $elm$core$Basics$append = _Utils_append;
var $elm$json$Json$Encode$encode = _Json_encode;
var $elm$core$String$fromInt = _String_fromNumber;
var $elm$core$String$join = F2(
	function (sep, chunks) {
		return A2(
			_String_join,
			sep,
			_List_toArray(chunks));
	});
var $elm$core$String$split = F2(
	function (sep, string) {
		return _List_fromArray(
			A2(_String_split, sep, string));
	});
var $elm$json$Json$Decode$indent = function (str) {
	return A2(
		$elm$core$String$join,
		'\n    ',
		A2($elm$core$String$split, '\n', str));
};
var $elm$core$List$foldl = F3(
	function (func, acc, list) {
		foldl:
		while (true) {
			if (!list.b) {
				return acc;
			} else {
				var x = list.a;
				var xs = list.b;
				var $temp$func = func,
					$temp$acc = A2(func, x, acc),
					$temp$list = xs;
				func = $temp$func;
				acc = $temp$acc;
				list = $temp$list;
				continue foldl;
			}
		}
	});
var $elm$core$List$length = function (xs) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (_v0, i) {
				return i + 1;
			}),
		0,
		xs);
};
var $elm$core$List$map2 = _List_map2;
var $elm$core$Basics$le = _Utils_le;
var $elm$core$Basics$sub = _Basics_sub;
var $elm$core$List$rangeHelp = F3(
	function (lo, hi, list) {
		rangeHelp:
		while (true) {
			if (_Utils_cmp(lo, hi) < 1) {
				var $temp$lo = lo,
					$temp$hi = hi - 1,
					$temp$list = A2($elm$core$List$cons, hi, list);
				lo = $temp$lo;
				hi = $temp$hi;
				list = $temp$list;
				continue rangeHelp;
			} else {
				return list;
			}
		}
	});
var $elm$core$List$range = F2(
	function (lo, hi) {
		return A3($elm$core$List$rangeHelp, lo, hi, _List_Nil);
	});
var $elm$core$List$indexedMap = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$map2,
			f,
			A2(
				$elm$core$List$range,
				0,
				$elm$core$List$length(xs) - 1),
			xs);
	});
var $elm$core$Char$toCode = _Char_toCode;
var $elm$core$Char$isLower = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (97 <= code) && (code <= 122);
};
var $elm$core$Char$isUpper = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (code <= 90) && (65 <= code);
};
var $elm$core$Basics$or = _Basics_or;
var $elm$core$Char$isAlpha = function (_char) {
	return $elm$core$Char$isLower(_char) || $elm$core$Char$isUpper(_char);
};
var $elm$core$Char$isDigit = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (code <= 57) && (48 <= code);
};
var $elm$core$Char$isAlphaNum = function (_char) {
	return $elm$core$Char$isLower(_char) || ($elm$core$Char$isUpper(_char) || $elm$core$Char$isDigit(_char));
};
var $elm$core$List$reverse = function (list) {
	return A3($elm$core$List$foldl, $elm$core$List$cons, _List_Nil, list);
};
var $elm$core$String$uncons = _String_uncons;
var $elm$json$Json$Decode$errorOneOf = F2(
	function (i, error) {
		return '\n\n(' + ($elm$core$String$fromInt(i + 1) + (') ' + $elm$json$Json$Decode$indent(
			$elm$json$Json$Decode$errorToString(error))));
	});
var $elm$json$Json$Decode$errorToString = function (error) {
	return A2($elm$json$Json$Decode$errorToStringHelp, error, _List_Nil);
};
var $elm$json$Json$Decode$errorToStringHelp = F2(
	function (error, context) {
		errorToStringHelp:
		while (true) {
			switch (error.$) {
				case 0:
					var f = error.a;
					var err = error.b;
					var isSimple = function () {
						var _v1 = $elm$core$String$uncons(f);
						if (_v1.$ === 1) {
							return false;
						} else {
							var _v2 = _v1.a;
							var _char = _v2.a;
							var rest = _v2.b;
							return $elm$core$Char$isAlpha(_char) && A2($elm$core$String$all, $elm$core$Char$isAlphaNum, rest);
						}
					}();
					var fieldName = isSimple ? ('.' + f) : ('[\'' + (f + '\']'));
					var $temp$error = err,
						$temp$context = A2($elm$core$List$cons, fieldName, context);
					error = $temp$error;
					context = $temp$context;
					continue errorToStringHelp;
				case 1:
					var i = error.a;
					var err = error.b;
					var indexName = '[' + ($elm$core$String$fromInt(i) + ']');
					var $temp$error = err,
						$temp$context = A2($elm$core$List$cons, indexName, context);
					error = $temp$error;
					context = $temp$context;
					continue errorToStringHelp;
				case 2:
					var errors = error.a;
					if (!errors.b) {
						return 'Ran into a Json.Decode.oneOf with no possibilities' + function () {
							if (!context.b) {
								return '!';
							} else {
								return ' at json' + A2(
									$elm$core$String$join,
									'',
									$elm$core$List$reverse(context));
							}
						}();
					} else {
						if (!errors.b.b) {
							var err = errors.a;
							var $temp$error = err,
								$temp$context = context;
							error = $temp$error;
							context = $temp$context;
							continue errorToStringHelp;
						} else {
							var starter = function () {
								if (!context.b) {
									return 'Json.Decode.oneOf';
								} else {
									return 'The Json.Decode.oneOf at json' + A2(
										$elm$core$String$join,
										'',
										$elm$core$List$reverse(context));
								}
							}();
							var introduction = starter + (' failed in the following ' + ($elm$core$String$fromInt(
								$elm$core$List$length(errors)) + ' ways:'));
							return A2(
								$elm$core$String$join,
								'\n\n',
								A2(
									$elm$core$List$cons,
									introduction,
									A2($elm$core$List$indexedMap, $elm$json$Json$Decode$errorOneOf, errors)));
						}
					}
				default:
					var msg = error.a;
					var json = error.b;
					var introduction = function () {
						if (!context.b) {
							return 'Problem with the given value:\n\n';
						} else {
							return 'Problem with the value at json' + (A2(
								$elm$core$String$join,
								'',
								$elm$core$List$reverse(context)) + ':\n\n    ');
						}
					}();
					return introduction + ($elm$json$Json$Decode$indent(
						A2($elm$json$Json$Encode$encode, 4, json)) + ('\n\n' + msg));
			}
		}
	});
var $elm$core$Array$branchFactor = 32;
var $elm$core$Array$Array_elm_builtin = F4(
	function (a, b, c, d) {
		return {$: 0, a: a, b: b, c: c, d: d};
	});
var $elm$core$Elm$JsArray$empty = _JsArray_empty;
var $elm$core$Basics$ceiling = _Basics_ceiling;
var $elm$core$Basics$fdiv = _Basics_fdiv;
var $elm$core$Basics$logBase = F2(
	function (base, number) {
		return _Basics_log(number) / _Basics_log(base);
	});
var $elm$core$Basics$toFloat = _Basics_toFloat;
var $elm$core$Array$shiftStep = $elm$core$Basics$ceiling(
	A2($elm$core$Basics$logBase, 2, $elm$core$Array$branchFactor));
var $elm$core$Array$empty = A4($elm$core$Array$Array_elm_builtin, 0, $elm$core$Array$shiftStep, $elm$core$Elm$JsArray$empty, $elm$core$Elm$JsArray$empty);
var $elm$core$Elm$JsArray$initialize = _JsArray_initialize;
var $elm$core$Array$Leaf = function (a) {
	return {$: 1, a: a};
};
var $elm$core$Basics$apL = F2(
	function (f, x) {
		return f(x);
	});
var $elm$core$Basics$apR = F2(
	function (x, f) {
		return f(x);
	});
var $elm$core$Basics$eq = _Utils_equal;
var $elm$core$Basics$floor = _Basics_floor;
var $elm$core$Elm$JsArray$length = _JsArray_length;
var $elm$core$Basics$gt = _Utils_gt;
var $elm$core$Basics$max = F2(
	function (x, y) {
		return (_Utils_cmp(x, y) > 0) ? x : y;
	});
var $elm$core$Basics$mul = _Basics_mul;
var $elm$core$Array$SubTree = function (a) {
	return {$: 0, a: a};
};
var $elm$core$Elm$JsArray$initializeFromList = _JsArray_initializeFromList;
var $elm$core$Array$compressNodes = F2(
	function (nodes, acc) {
		compressNodes:
		while (true) {
			var _v0 = A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, nodes);
			var node = _v0.a;
			var remainingNodes = _v0.b;
			var newAcc = A2(
				$elm$core$List$cons,
				$elm$core$Array$SubTree(node),
				acc);
			if (!remainingNodes.b) {
				return $elm$core$List$reverse(newAcc);
			} else {
				var $temp$nodes = remainingNodes,
					$temp$acc = newAcc;
				nodes = $temp$nodes;
				acc = $temp$acc;
				continue compressNodes;
			}
		}
	});
var $elm$core$Tuple$first = function (_v0) {
	var x = _v0.a;
	return x;
};
var $elm$core$Array$treeFromBuilder = F2(
	function (nodeList, nodeListSize) {
		treeFromBuilder:
		while (true) {
			var newNodeSize = $elm$core$Basics$ceiling(nodeListSize / $elm$core$Array$branchFactor);
			if (newNodeSize === 1) {
				return A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, nodeList).a;
			} else {
				var $temp$nodeList = A2($elm$core$Array$compressNodes, nodeList, _List_Nil),
					$temp$nodeListSize = newNodeSize;
				nodeList = $temp$nodeList;
				nodeListSize = $temp$nodeListSize;
				continue treeFromBuilder;
			}
		}
	});
var $elm$core$Array$builderToArray = F2(
	function (reverseNodeList, builder) {
		if (!builder.n) {
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.r),
				$elm$core$Array$shiftStep,
				$elm$core$Elm$JsArray$empty,
				builder.r);
		} else {
			var treeLen = builder.n * $elm$core$Array$branchFactor;
			var depth = $elm$core$Basics$floor(
				A2($elm$core$Basics$logBase, $elm$core$Array$branchFactor, treeLen - 1));
			var correctNodeList = reverseNodeList ? $elm$core$List$reverse(builder.s) : builder.s;
			var tree = A2($elm$core$Array$treeFromBuilder, correctNodeList, builder.n);
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.r) + treeLen,
				A2($elm$core$Basics$max, 5, depth * $elm$core$Array$shiftStep),
				tree,
				builder.r);
		}
	});
var $elm$core$Basics$idiv = _Basics_idiv;
var $elm$core$Basics$lt = _Utils_lt;
var $elm$core$Array$initializeHelp = F5(
	function (fn, fromIndex, len, nodeList, tail) {
		initializeHelp:
		while (true) {
			if (fromIndex < 0) {
				return A2(
					$elm$core$Array$builderToArray,
					false,
					{s: nodeList, n: (len / $elm$core$Array$branchFactor) | 0, r: tail});
			} else {
				var leaf = $elm$core$Array$Leaf(
					A3($elm$core$Elm$JsArray$initialize, $elm$core$Array$branchFactor, fromIndex, fn));
				var $temp$fn = fn,
					$temp$fromIndex = fromIndex - $elm$core$Array$branchFactor,
					$temp$len = len,
					$temp$nodeList = A2($elm$core$List$cons, leaf, nodeList),
					$temp$tail = tail;
				fn = $temp$fn;
				fromIndex = $temp$fromIndex;
				len = $temp$len;
				nodeList = $temp$nodeList;
				tail = $temp$tail;
				continue initializeHelp;
			}
		}
	});
var $elm$core$Basics$remainderBy = _Basics_remainderBy;
var $elm$core$Array$initialize = F2(
	function (len, fn) {
		if (len <= 0) {
			return $elm$core$Array$empty;
		} else {
			var tailLen = len % $elm$core$Array$branchFactor;
			var tail = A3($elm$core$Elm$JsArray$initialize, tailLen, len - tailLen, fn);
			var initialFromIndex = (len - tailLen) - $elm$core$Array$branchFactor;
			return A5($elm$core$Array$initializeHelp, fn, initialFromIndex, len, _List_Nil, tail);
		}
	});
var $elm$core$Basics$True = 0;
var $elm$core$Result$isOk = function (result) {
	if (!result.$) {
		return true;
	} else {
		return false;
	}
};
var $elm$json$Json$Decode$map = _Json_map1;
var $elm$json$Json$Decode$map2 = _Json_map2;
var $elm$json$Json$Decode$succeed = _Json_succeed;
var $elm$virtual_dom$VirtualDom$toHandlerInt = function (handler) {
	switch (handler.$) {
		case 0:
			return 0;
		case 1:
			return 1;
		case 2:
			return 2;
		default:
			return 3;
	}
};
var $elm$browser$Browser$External = function (a) {
	return {$: 1, a: a};
};
var $elm$browser$Browser$Internal = function (a) {
	return {$: 0, a: a};
};
var $elm$core$Basics$identity = function (x) {
	return x;
};
var $elm$browser$Browser$Dom$NotFound = $elm$core$Basics$identity;
var $elm$url$Url$Http = 0;
var $elm$url$Url$Https = 1;
var $elm$url$Url$Url = F6(
	function (protocol, host, port_, path, query, fragment) {
		return {es: fragment, ex: host, e3: path, e5: port_, e9: protocol, fa: query};
	});
var $elm$core$String$contains = _String_contains;
var $elm$core$String$length = _String_length;
var $elm$core$String$slice = _String_slice;
var $elm$core$String$dropLeft = F2(
	function (n, string) {
		return (n < 1) ? string : A3(
			$elm$core$String$slice,
			n,
			$elm$core$String$length(string),
			string);
	});
var $elm$core$String$indexes = _String_indexes;
var $elm$core$String$isEmpty = function (string) {
	return string === '';
};
var $elm$core$String$left = F2(
	function (n, string) {
		return (n < 1) ? '' : A3($elm$core$String$slice, 0, n, string);
	});
var $elm$core$String$toInt = _String_toInt;
var $elm$url$Url$chompBeforePath = F5(
	function (protocol, path, params, frag, str) {
		if ($elm$core$String$isEmpty(str) || A2($elm$core$String$contains, '@', str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, ':', str);
			if (!_v0.b) {
				return $elm$core$Maybe$Just(
					A6($elm$url$Url$Url, protocol, str, $elm$core$Maybe$Nothing, path, params, frag));
			} else {
				if (!_v0.b.b) {
					var i = _v0.a;
					var _v1 = $elm$core$String$toInt(
						A2($elm$core$String$dropLeft, i + 1, str));
					if (_v1.$ === 1) {
						return $elm$core$Maybe$Nothing;
					} else {
						var port_ = _v1;
						return $elm$core$Maybe$Just(
							A6(
								$elm$url$Url$Url,
								protocol,
								A2($elm$core$String$left, i, str),
								port_,
								path,
								params,
								frag));
					}
				} else {
					return $elm$core$Maybe$Nothing;
				}
			}
		}
	});
var $elm$url$Url$chompBeforeQuery = F4(
	function (protocol, params, frag, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '/', str);
			if (!_v0.b) {
				return A5($elm$url$Url$chompBeforePath, protocol, '/', params, frag, str);
			} else {
				var i = _v0.a;
				return A5(
					$elm$url$Url$chompBeforePath,
					protocol,
					A2($elm$core$String$dropLeft, i, str),
					params,
					frag,
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$url$Url$chompBeforeFragment = F3(
	function (protocol, frag, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '?', str);
			if (!_v0.b) {
				return A4($elm$url$Url$chompBeforeQuery, protocol, $elm$core$Maybe$Nothing, frag, str);
			} else {
				var i = _v0.a;
				return A4(
					$elm$url$Url$chompBeforeQuery,
					protocol,
					$elm$core$Maybe$Just(
						A2($elm$core$String$dropLeft, i + 1, str)),
					frag,
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$url$Url$chompAfterProtocol = F2(
	function (protocol, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '#', str);
			if (!_v0.b) {
				return A3($elm$url$Url$chompBeforeFragment, protocol, $elm$core$Maybe$Nothing, str);
			} else {
				var i = _v0.a;
				return A3(
					$elm$url$Url$chompBeforeFragment,
					protocol,
					$elm$core$Maybe$Just(
						A2($elm$core$String$dropLeft, i + 1, str)),
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$core$String$startsWith = _String_startsWith;
var $elm$url$Url$fromString = function (str) {
	return A2($elm$core$String$startsWith, 'http://', str) ? A2(
		$elm$url$Url$chompAfterProtocol,
		0,
		A2($elm$core$String$dropLeft, 7, str)) : (A2($elm$core$String$startsWith, 'https://', str) ? A2(
		$elm$url$Url$chompAfterProtocol,
		1,
		A2($elm$core$String$dropLeft, 8, str)) : $elm$core$Maybe$Nothing);
};
var $elm$core$Basics$never = function (_v0) {
	never:
	while (true) {
		var nvr = _v0;
		var $temp$_v0 = nvr;
		_v0 = $temp$_v0;
		continue never;
	}
};
var $elm$core$Task$Perform = $elm$core$Basics$identity;
var $elm$core$Task$succeed = _Scheduler_succeed;
var $elm$core$Task$init = $elm$core$Task$succeed(0);
var $elm$core$List$foldrHelper = F4(
	function (fn, acc, ctr, ls) {
		if (!ls.b) {
			return acc;
		} else {
			var a = ls.a;
			var r1 = ls.b;
			if (!r1.b) {
				return A2(fn, a, acc);
			} else {
				var b = r1.a;
				var r2 = r1.b;
				if (!r2.b) {
					return A2(
						fn,
						a,
						A2(fn, b, acc));
				} else {
					var c = r2.a;
					var r3 = r2.b;
					if (!r3.b) {
						return A2(
							fn,
							a,
							A2(
								fn,
								b,
								A2(fn, c, acc)));
					} else {
						var d = r3.a;
						var r4 = r3.b;
						var res = (ctr > 500) ? A3(
							$elm$core$List$foldl,
							fn,
							acc,
							$elm$core$List$reverse(r4)) : A4($elm$core$List$foldrHelper, fn, acc, ctr + 1, r4);
						return A2(
							fn,
							a,
							A2(
								fn,
								b,
								A2(
									fn,
									c,
									A2(fn, d, res))));
					}
				}
			}
		}
	});
var $elm$core$List$foldr = F3(
	function (fn, acc, ls) {
		return A4($elm$core$List$foldrHelper, fn, acc, 0, ls);
	});
var $elm$core$List$map = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (x, acc) {
					return A2(
						$elm$core$List$cons,
						f(x),
						acc);
				}),
			_List_Nil,
			xs);
	});
var $elm$core$Task$andThen = _Scheduler_andThen;
var $elm$core$Task$map = F2(
	function (func, taskA) {
		return A2(
			$elm$core$Task$andThen,
			function (a) {
				return $elm$core$Task$succeed(
					func(a));
			},
			taskA);
	});
var $elm$core$Task$map2 = F3(
	function (func, taskA, taskB) {
		return A2(
			$elm$core$Task$andThen,
			function (a) {
				return A2(
					$elm$core$Task$andThen,
					function (b) {
						return $elm$core$Task$succeed(
							A2(func, a, b));
					},
					taskB);
			},
			taskA);
	});
var $elm$core$Task$sequence = function (tasks) {
	return A3(
		$elm$core$List$foldr,
		$elm$core$Task$map2($elm$core$List$cons),
		$elm$core$Task$succeed(_List_Nil),
		tasks);
};
var $elm$core$Platform$sendToApp = _Platform_sendToApp;
var $elm$core$Task$spawnCmd = F2(
	function (router, _v0) {
		var task = _v0;
		return _Scheduler_spawn(
			A2(
				$elm$core$Task$andThen,
				$elm$core$Platform$sendToApp(router),
				task));
	});
var $elm$core$Task$onEffects = F3(
	function (router, commands, state) {
		return A2(
			$elm$core$Task$map,
			function (_v0) {
				return 0;
			},
			$elm$core$Task$sequence(
				A2(
					$elm$core$List$map,
					$elm$core$Task$spawnCmd(router),
					commands)));
	});
var $elm$core$Task$onSelfMsg = F3(
	function (_v0, _v1, _v2) {
		return $elm$core$Task$succeed(0);
	});
var $elm$core$Task$cmdMap = F2(
	function (tagger, _v0) {
		var task = _v0;
		return A2($elm$core$Task$map, tagger, task);
	});
_Platform_effectManagers['Task'] = _Platform_createManager($elm$core$Task$init, $elm$core$Task$onEffects, $elm$core$Task$onSelfMsg, $elm$core$Task$cmdMap);
var $elm$core$Task$command = _Platform_leaf('Task');
var $elm$core$Task$perform = F2(
	function (toMessage, task) {
		return $elm$core$Task$command(
			A2($elm$core$Task$map, toMessage, task));
	});
var $elm$browser$Browser$application = _Browser_application;
var $author$project$Main$Setup = {$: 0};
var $elm$core$Platform$Cmd$batch = _Platform_batch;
var $elm$core$Platform$Cmd$none = $elm$core$Platform$Cmd$batch(_List_Nil);
var $author$project$Main$init = F3(
	function (_v0, _v1, _v2) {
		return _Utils_Tuple2($author$project$Main$Setup, $elm$core$Platform$Cmd$none);
	});
var $author$project$Main$FileLoaded = function (a) {
	return {$: 4, a: a};
};
var $author$project$Main$FileSaved = function (a) {
	return {$: 5, a: a};
};
var $elm$core$Platform$Sub$batch = _Platform_batch;
var $elm$json$Json$Decode$string = _Json_decodeString;
var $author$project$Main$fileContent = _Platform_incomingPort('fileContent', $elm$json$Json$Decode$string);
var $elm$json$Json$Decode$int = _Json_decodeInt;
var $author$project$Main$fileSaved = _Platform_incomingPort('fileSaved', $elm$json$Json$Decode$int);
var $author$project$Main$subscriptions = function (_v0) {
	return $elm$core$Platform$Sub$batch(
		_List_fromArray(
			[
				$author$project$Main$fileContent($author$project$Main$FileLoaded),
				$author$project$Main$fileSaved($author$project$Main$FileSaved)
			]));
};
var $author$project$Main$Content = F3(
	function (tab, slipbox, sideNavState) {
		return {cl: sideNavState, Y: slipbox, l: tab};
	});
var $author$project$Main$CreateModeTab = function (a) {
	return {$: 1, a: a};
};
var $author$project$Main$DiscoveryModeTab = function (a) {
	return {$: 2, a: a};
};
var $author$project$Main$EditModeTab = function (a) {
	return {$: 0, a: a};
};
var $author$project$Main$Expanded = 0;
var $author$project$Main$ExportModeTab = function (a) {
	return {$: 3, a: a};
};
var $author$project$Main$FailureToParse = {$: 1};
var $author$project$Main$Session = function (a) {
	return {$: 2, a: a};
};
var $author$project$Discovery$ChooseDiscussion = function (a) {
	return {$: 1, a: a};
};
var $author$project$Discovery$init = $author$project$Discovery$ChooseDiscussion('');
var $author$project$Discovery$back = function (discovery) {
	if (discovery.$ === 1) {
		return discovery;
	} else {
		return $author$project$Discovery$init;
	}
};
var $author$project$Edit$NoteSelected = function (a) {
	return {$: 1, a: a};
};
var $author$project$Edit$cancel = function (edit) {
	switch (edit.$) {
		case 3:
			var previousNoteSelected = edit.a;
			return $author$project$Edit$NoteSelected(previousNoteSelected);
		case 4:
			var previousNoteSelected = edit.b;
			return $author$project$Edit$NoteSelected(previousNoteSelected);
		default:
			return edit;
	}
};
var $elm$json$Json$Encode$null = _Json_encodeNull;
var $author$project$Main$changesMade = _Platform_outgoingPort(
	'changesMade',
	function ($) {
		return $elm$json$Json$Encode$null;
	});
var $author$project$Slipbox$Slipbox = $elm$core$Basics$identity;
var $author$project$Link$Info = F3(
	function (id, sourceId, targetId) {
		return {cT: id, dI: sourceId, dL: targetId};
	});
var $author$project$Link$Link = $elm$core$Basics$identity;
var $author$project$IdGenerator$IdGenerator = $elm$core$Basics$identity;
var $author$project$IdGenerator$generateId = function (generator) {
	var id = generator;
	return _Utils_Tuple2(id, id + 1);
};
var $author$project$Note$getInfo = function (note) {
	var content = note;
	return content;
};
var $author$project$Note$getId = function (note) {
	return $author$project$Note$getInfo(note).cT;
};
var $author$project$Link$create = F3(
	function (generator, sourceNote, targetNote) {
		var _v0 = $author$project$IdGenerator$generateId(generator);
		var id = _v0.a;
		var idGenerator = _v0.b;
		return _Utils_Tuple2(
			A3(
				$author$project$Link$Info,
				id,
				$author$project$Note$getId(sourceNote),
				$author$project$Note$getId(targetNote)),
			idGenerator);
	});
var $author$project$Slipbox$getContent = function (slipbox) {
	var content = slipbox;
	return content;
};
var $author$project$Slipbox$addLink = F3(
	function (note1, note2, slipbox) {
		var content = $author$project$Slipbox$getContent(slipbox);
		var _v0 = A3($author$project$Link$create, content.ae, note1, note2);
		var link = _v0.a;
		var idGenerator = _v0.b;
		var links = A2($elm$core$List$cons, link, content.gT);
		return _Utils_update(
			content,
			{ae: idGenerator, gT: links, aJ: true});
	});
var $elm$core$List$filter = F2(
	function (isGood, list) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (x, xs) {
					return isGood(x) ? A2($elm$core$List$cons, x, xs) : xs;
				}),
			_List_Nil,
			list);
	});
var $author$project$Link$getInfo = function (link) {
	var info = link;
	return info;
};
var $author$project$Link$getId = function (link) {
	return $author$project$Link$getInfo(link).cT;
};
var $author$project$Link$is = F2(
	function (link1, link2) {
		return _Utils_eq(
			$author$project$Link$getId(link1),
			$author$project$Link$getId(link2));
	});
var $elm$core$Basics$not = _Basics_not;
var $author$project$Slipbox$breakLink = F2(
	function (link, slipbox) {
		var content = $author$project$Slipbox$getContent(slipbox);
		return _Utils_update(
			content,
			{
				gT: A2(
					$elm$core$List$filter,
					function (l) {
						return !A2($author$project$Link$is, l, link);
					},
					content.gT),
				aJ: true
			});
	});
var $author$project$Edit$confirm = F2(
	function (slipbox, edit) {
		switch (edit.$) {
			case 3:
				var previousNoteSelected = edit.a;
				var link = edit.b;
				return _Utils_Tuple2(
					A2($author$project$Slipbox$breakLink, link, slipbox),
					$author$project$Edit$NoteSelected(previousNoteSelected));
			case 4:
				var previousNoteSelected = edit.b;
				var notesToLink = edit.c;
				return _Utils_Tuple2(
					A3(
						$elm$core$List$foldl,
						$author$project$Slipbox$addLink(previousNoteSelected),
						slipbox,
						notesToLink),
					$author$project$Edit$NoteSelected(previousNoteSelected));
			default:
				return _Utils_Tuple2(slipbox, edit);
		}
	});
var $author$project$Export$ConfigureContent = F2(
	function (a, b) {
		return {$: 3, a: a, b: b};
	});
var $author$project$Export$PromptAnotherExport = {$: 4};
var $author$project$Export$SelectDiscussions = F3(
	function (a, b, c) {
		return {$: 2, a: a, b: b, c: c};
	});
var $elm$core$List$isEmpty = function (xs) {
	if (!xs.b) {
		return true;
	} else {
		return false;
	}
};
var $author$project$Export$isSelected = function (discussion) {
	if (!discussion.$) {
		return true;
	} else {
		return false;
	}
};
var $author$project$Export$atLeastOneDiscussionWasChosen = function (discussions) {
	return !$elm$core$List$isEmpty(
		A2($elm$core$List$filter, $author$project$Export$isSelected, discussions));
};
var $elm$core$List$append = F2(
	function (xs, ys) {
		if (!ys.b) {
			return xs;
		} else {
			return A3($elm$core$List$foldr, $elm$core$List$cons, ys, xs);
		}
	});
var $elm$core$List$concat = function (lists) {
	return A3($elm$core$List$foldr, $elm$core$List$append, _List_Nil, lists);
};
var $elm$core$List$concatMap = F2(
	function (f, list) {
		return $elm$core$List$concat(
			A2($elm$core$List$map, f, list));
	});
var $author$project$Slipbox$flatten2D = function (list) {
	return A3($elm$core$List$foldr, $elm$core$Basics$append, _List_Nil, list);
};
var $elm$core$List$head = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(x);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $author$project$Link$getSourceId = function (link) {
	return $author$project$Link$getInfo(link).dI;
};
var $author$project$Note$isNoteFromId = F2(
	function (id, note) {
		return _Utils_eq(
			$author$project$Note$getId(note),
			id);
	});
var $author$project$Link$isSource = F2(
	function (link, note) {
		return A2(
			$author$project$Note$isNoteFromId,
			$author$project$Link$getSourceId(link),
			note);
	});
var $author$project$Link$getTargetId = function (link) {
	return $author$project$Link$getInfo(link).dL;
};
var $author$project$Link$isTarget = F2(
	function (link, note) {
		return A2(
			$author$project$Note$isNoteFromId,
			$author$project$Link$getTargetId(link),
			note);
	});
var $author$project$Slipbox$convertLinktoLinkNoteTuple = F3(
	function (targetNote, notes, link) {
		if (A2($author$project$Link$isTarget, link, targetNote)) {
			var _v0 = $elm$core$List$head(
				A2(
					$elm$core$List$filter,
					$author$project$Link$isSource(link),
					notes));
			if (!_v0.$) {
				var note = _v0.a;
				return $elm$core$Maybe$Just(
					_Utils_Tuple2(note, link));
			} else {
				return $elm$core$Maybe$Nothing;
			}
		} else {
			if (A2($author$project$Link$isSource, link, targetNote)) {
				var _v1 = $elm$core$List$head(
					A2(
						$elm$core$List$filter,
						$author$project$Link$isTarget(link),
						notes));
				if (!_v1.$) {
					var note = _v1.a;
					return $elm$core$Maybe$Just(
						_Utils_Tuple2(note, link));
				} else {
					return $elm$core$Maybe$Nothing;
				}
			} else {
				return $elm$core$Maybe$Nothing;
			}
		}
	});
var $elm$core$List$maybeCons = F3(
	function (f, mx, xs) {
		var _v0 = f(mx);
		if (!_v0.$) {
			var x = _v0.a;
			return A2($elm$core$List$cons, x, xs);
		} else {
			return xs;
		}
	});
var $elm$core$List$filterMap = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$foldr,
			$elm$core$List$maybeCons(f),
			_List_Nil,
			xs);
	});
var $author$project$Slipbox$isAssociated = F2(
	function (note, link) {
		return A2($author$project$Link$isSource, link, note) || A2($author$project$Link$isTarget, link, note);
	});
var $author$project$Slipbox$getLinkedNotes_ = F3(
	function (note, notes, links) {
		var relevantLinks = A2(
			$elm$core$List$filter,
			$author$project$Slipbox$isAssociated(note),
			links);
		return A2(
			$elm$core$List$filterMap,
			A2($author$project$Slipbox$convertLinktoLinkNoteTuple, note, notes),
			relevantLinks);
	});
var $author$project$Note$Discussion = 1;
var $author$project$Note$getVariant = function (note) {
	return $author$project$Note$getInfo(note).bo;
};
var $author$project$Note$is = F2(
	function (note1, note2) {
		return _Utils_eq(
			$author$project$Note$getId(note1),
			$author$project$Note$getId(note2));
	});
var $author$project$Slipbox$isADifferentDiscussion = F2(
	function (note, discussion) {
		return ($author$project$Note$getVariant(note) === 1) && (!A2($author$project$Note$is, note, discussion));
	});
var $elm$core$List$any = F2(
	function (isOkay, list) {
		any:
		while (true) {
			if (!list.b) {
				return false;
			} else {
				var x = list.a;
				var xs = list.b;
				if (isOkay(x)) {
					return true;
				} else {
					var $temp$isOkay = isOkay,
						$temp$list = xs;
					isOkay = $temp$isOkay;
					list = $temp$list;
					continue any;
				}
			}
		}
	});
var $author$project$Slipbox$getLinkedNotes = F2(
	function (note, slipbox) {
		var content = $author$project$Slipbox$getContent(slipbox);
		var relevantLinks = A2(
			$elm$core$List$filter,
			$author$project$Slipbox$isAssociated(note),
			content.gT);
		return A2(
			$elm$core$List$filterMap,
			A2($author$project$Slipbox$convertLinktoLinkNoteTuple, note, content.R),
			relevantLinks);
	});
var $author$project$Slipbox$noteIsEntryPointForDifferentDiscussion = F3(
	function (note, discussion, slipbox) {
		var noteLinkTuples = A2($author$project$Slipbox$getLinkedNotes, note, slipbox);
		var isEntryPointForGivenDiscussion = A2(
			$elm$core$List$any,
			function (_v1) {
				var linkedNote = _v1.a;
				return A2($author$project$Note$is, linkedNote, discussion);
			},
			noteLinkTuples);
		var differentLinkedDiscussions = A2(
			$elm$core$List$filter,
			function (_v0) {
				var linkedNote = _v0.a;
				return A2($author$project$Slipbox$isADifferentDiscussion, linkedNote, discussion);
			},
			noteLinkTuples);
		return ($elm$core$List$isEmpty(differentLinkedDiscussions) || isEntryPointForGivenDiscussion) ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(differentLinkedDiscussions);
	});
var $elm$core$Tuple$second = function (_v0) {
	var y = _v0.b;
	return y;
};
var $author$project$Slipbox$getDiscussionTreeWithCollapsedDiscussions = F2(
	function (discussion, slipbox) {
		var content = $author$project$Slipbox$getContent(slipbox);
		var recurs = F2(
			function (rootNote, links) {
				return A2($author$project$Slipbox$isADifferentDiscussion, rootNote, discussion) ? _List_Nil : $author$project$Slipbox$flatten2D(
					A2(
						$elm$core$List$map,
						function (_v0) {
							var linkedNote = _v0.a;
							var link = _v0.b;
							var _v1 = A3($author$project$Slipbox$noteIsEntryPointForDifferentDiscussion, linkedNote, discussion, slipbox);
							if (!_v1.$) {
								var differentDiscussionList = _v1.a;
								return A2(
									$elm$core$List$cons,
									_Utils_Tuple2(linkedNote, link),
									differentDiscussionList);
							} else {
								return A2(
									$elm$core$List$cons,
									_Utils_Tuple2(linkedNote, link),
									A2(
										recurs,
										linkedNote,
										A2(
											$elm$core$List$filter,
											function (l) {
												return !A2($author$project$Link$is, link, l);
											},
											links)));
							}
						},
						A3($author$project$Slipbox$getLinkedNotes_, rootNote, content.R, links)));
			});
		var allTuples = A2(recurs, discussion, content.gT);
		return _Utils_Tuple2(
			A2(
				$elm$core$List$cons,
				discussion,
				A2($elm$core$List$map, $elm$core$Tuple$first, allTuples)),
			A2($elm$core$List$map, $elm$core$Tuple$second, allTuples));
	});
var $author$project$SourceTitle$getTitle = function (st) {
	if (!st.$) {
		var title = st.a;
		return $elm$core$Maybe$Just(title);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $elm$core$String$toLower = _String_toLower;
var $author$project$Note$contains = F2(
	function (string, note) {
		var info = $author$project$Note$getInfo(note);
		var has = function (s) {
			return A2(
				$elm$core$String$contains,
				$elm$core$String$toLower(string),
				$elm$core$String$toLower(s));
		};
		var containsSourceTitle = function () {
			var _v0 = $author$project$SourceTitle$getTitle(info.bM);
			if (!_v0.$) {
				var sourceTitle = _v0.a;
				return has(sourceTitle);
			} else {
				return false;
			}
		}();
		return has(info.aP) || containsSourceTitle;
	});
var $author$project$Slipbox$isQuestion = function (note) {
	return $author$project$Note$getVariant(note) === 1;
};
var $author$project$Slipbox$getDiscussions = F2(
	function (maybeSearch, slipbox) {
		var content = $author$project$Slipbox$getContent(slipbox);
		if (!maybeSearch.$) {
			var search = maybeSearch.a;
			return A2(
				$elm$core$List$filter,
				$author$project$Slipbox$isQuestion,
				A2(
					$elm$core$List$filter,
					$author$project$Note$contains(search),
					content.R));
		} else {
			return A2($elm$core$List$filter, $author$project$Slipbox$isQuestion, content.R);
		}
	});
var $author$project$Export$getNote = function (discussion) {
	if (!discussion.$) {
		var note = discussion.a;
		return note;
	} else {
		var note = discussion.a;
		return note;
	}
};
var $author$project$Export$ErrorStateNoDiscussions = {$: 0};
var $author$project$Export$InputProjectTitle = function (a) {
	return {$: 1, a: a};
};
var $author$project$Export$init = function (slipbox) {
	var discussions = A2($author$project$Slipbox$getDiscussions, $elm$core$Maybe$Nothing, slipbox);
	return $elm$core$List$isEmpty(discussions) ? $author$project$Export$ErrorStateNoDiscussions : $author$project$Export$InputProjectTitle('');
};
var $author$project$Export$Unselected = function (a) {
	return {$: 1, a: a};
};
var $author$project$Export$toUnselectedDiscussion = function (note) {
	return $author$project$Export$Unselected(note);
};
var $author$project$Export$continue = F2(
	function (slipbox, _export) {
		switch (_export.$) {
			case 1:
				var title = _export.a;
				return $elm$core$String$isEmpty(title) ? _export : A3(
					$author$project$Export$SelectDiscussions,
					title,
					'',
					A2(
						$elm$core$List$map,
						$author$project$Export$toUnselectedDiscussion,
						A2($author$project$Slipbox$getDiscussions, $elm$core$Maybe$Nothing, slipbox)));
			case 2:
				var title = _export.a;
				var discussions = _export.c;
				if (!$author$project$Export$atLeastOneDiscussionWasChosen(discussions)) {
					return _export;
				} else {
					var selectedDiscussions = A2(
						$elm$core$List$map,
						$author$project$Export$getNote,
						A2($elm$core$List$filter, $author$project$Export$isSelected, discussions));
					var notes = A2(
						$elm$core$List$concatMap,
						function (n) {
							return A2($author$project$Slipbox$getDiscussionTreeWithCollapsedDiscussions, n, slipbox).a;
						},
						selectedDiscussions);
					return A2($author$project$Export$ConfigureContent, title, notes);
				}
			case 3:
				return $author$project$Export$PromptAnotherExport;
			case 4:
				return $author$project$Export$init(slipbox);
			default:
				return _export;
		}
	});
var $author$project$Create$FindLinksForDiscussion = F6(
	function (a, b, c, d, e, f) {
		return {$: 2, a: a, b: b, c: c, d: d, e: e, f: f};
	});
var $author$project$Create$getCreatedLinks = function (internal) {
	var links = internal.c;
	return links;
};
var $author$project$Create$getNoteOnLink = function (link) {
	var note = link;
	return note;
};
var $author$project$Create$linkIsForNote = F2(
	function (note, link) {
		return A2(
			$author$project$Note$is,
			note,
			$author$project$Create$getNoteOnLink(link));
	});
var $author$project$Create$CreateModeInternal = F5(
	function (a, b, c, d, e) {
		return {$: 0, a: a, b: b, c: c, d: d, e: e};
	});
var $author$project$Create$setCreatedLinks = F2(
	function (linksCreated, internal) {
		var note = internal.a;
		var questionsRead = internal.b;
		var source = internal.d;
		var discussion = internal.e;
		return A5($author$project$Create$CreateModeInternal, note, questionsRead, linksCreated, source, discussion);
	});
var $author$project$Create$addLink = F2(
	function (newLink, internal) {
		var note = $author$project$Create$getNoteOnLink(newLink);
		var links = $author$project$Create$getCreatedLinks(internal);
		var linkIdentifier = $author$project$Create$linkIsForNote(note);
		var linkToNoteAlreadyExists = A2($elm$core$List$any, linkIdentifier, links);
		var updatedCreatedLinks = linkToNoteAlreadyExists ? A2(
			$elm$core$List$map,
			function (link) {
				return linkIdentifier(link) ? newLink : link;
			},
			links) : A2($elm$core$List$cons, newLink, links);
		return A2($author$project$Create$setCreatedLinks, updatedCreatedLinks, internal);
	});
var $author$project$Create$Link = $elm$core$Basics$identity;
var $author$project$Create$makeLink = function (note) {
	return note;
};
var $author$project$Create$createLink = function (create) {
	if (create.$ === 2) {
		var coachingModal = create.a;
		var graph = create.b;
		var createModeInternal = create.c;
		var question = create.d;
		var selectedNote = create.e;
		var hoveredNote = create.f;
		return A6(
			$author$project$Create$FindLinksForDiscussion,
			coachingModal,
			graph,
			A2(
				$author$project$Create$addLink,
				$author$project$Create$makeLink(selectedNote),
				createModeInternal),
			question,
			selectedNote,
			hoveredNote);
	} else {
		return create;
	}
};
var $author$project$Slipbox$Content = F5(
	function (notes, links, sources, idGenerator, unsavedChanges) {
		return {ae: idGenerator, gT: links, R: notes, bi: sources, aJ: unsavedChanges};
	});
var $author$project$IdGenerator$decode = A2($elm$json$Json$Decode$map, $elm$core$Basics$identity, $elm$json$Json$Decode$int);
var $elm$json$Json$Decode$field = _Json_decodeField;
var $author$project$Link$link_ = F3(
	function (id, source, target) {
		return A3($author$project$Link$Info, id, source, target);
	});
var $elm$json$Json$Decode$map3 = _Json_map3;
var $author$project$Link$decode = A4(
	$elm$json$Json$Decode$map3,
	$author$project$Link$link_,
	A2($elm$json$Json$Decode$field, 'id', $elm$json$Json$Decode$int),
	A2($elm$json$Json$Decode$field, 'sourceId', $elm$json$Json$Decode$int),
	A2($elm$json$Json$Decode$field, 'targetId', $elm$json$Json$Decode$int));
var $elm$json$Json$Decode$map4 = _Json_map4;
var $author$project$Note$Info = F4(
	function (id, content, sourceTitle, variant) {
		return {aP: content, cT: id, bM: sourceTitle, bo: variant};
	});
var $author$project$Note$Note = $elm$core$Basics$identity;
var $author$project$SourceTitle$HasSource = function (a) {
	return {$: 0, a: a};
};
var $author$project$SourceTitle$NoSource = {$: 1};
var $author$project$SourceTitle$titleIsNotEmpty = function (title) {
	return !$elm$core$String$isEmpty(title);
};
var $elm$core$Basics$neq = _Utils_notEqual;
var $author$project$SourceTitle$noSourceEncoding = 'n/a';
var $author$project$SourceTitle$titleIsNotNA = function (title) {
	return !_Utils_eq(
		$elm$core$String$toLower(title),
		$author$project$SourceTitle$noSourceEncoding);
};
var $author$project$SourceTitle$isValid = function (title) {
	return $author$project$SourceTitle$titleIsNotEmpty(title) && $author$project$SourceTitle$titleIsNotNA(title);
};
var $author$project$SourceTitle$sourceTitle = function (title) {
	return $author$project$SourceTitle$isValid(title) ? $author$project$SourceTitle$HasSource(title) : $author$project$SourceTitle$NoSource;
};
var $author$project$Note$Regular = 0;
var $author$project$Note$stringToVariant = function (string) {
	switch (string) {
		case 'regular':
			return 0;
		case 'index':
			return 1;
		default:
			return 0;
	}
};
var $author$project$Note$note_ = F4(
	function (id, content, source, variant) {
		return A4(
			$author$project$Note$Info,
			id,
			content,
			$author$project$SourceTitle$sourceTitle(source),
			$author$project$Note$stringToVariant(variant));
	});
var $author$project$Note$decode = A5(
	$elm$json$Json$Decode$map4,
	$author$project$Note$note_,
	A2($elm$json$Json$Decode$field, 'id', $elm$json$Json$Decode$int),
	A2($elm$json$Json$Decode$field, 'content', $elm$json$Json$Decode$string),
	A2($elm$json$Json$Decode$field, 'source', $elm$json$Json$Decode$string),
	A2($elm$json$Json$Decode$field, 'variant', $elm$json$Json$Decode$string));
var $author$project$Source$Info = F4(
	function (id, title, author, content) {
		return {fX: author, aP: content, cT: id, dO: title};
	});
var $author$project$Source$Source = $elm$core$Basics$identity;
var $author$project$Source$source_ = F4(
	function (id, title, author, content) {
		return A4($author$project$Source$Info, id, title, author, content);
	});
var $author$project$Source$decode = A5(
	$elm$json$Json$Decode$map4,
	$author$project$Source$source_,
	A2($elm$json$Json$Decode$field, 'id', $elm$json$Json$Decode$int),
	A2($elm$json$Json$Decode$field, 'title', $elm$json$Json$Decode$string),
	A2($elm$json$Json$Decode$field, 'author', $elm$json$Json$Decode$string),
	A2($elm$json$Json$Decode$field, 'content', $elm$json$Json$Decode$string));
var $elm$json$Json$Decode$list = _Json_decodeList;
var $author$project$Slipbox$decode = function () {
	var slipbox = F4(
		function (notes, links, sources, idGenerator) {
			return A5($author$project$Slipbox$Content, notes, links, sources, idGenerator, false);
		});
	return A5(
		$elm$json$Json$Decode$map4,
		slipbox,
		A2(
			$elm$json$Json$Decode$field,
			'notes',
			$elm$json$Json$Decode$list($author$project$Note$decode)),
		A2(
			$elm$json$Json$Decode$field,
			'links',
			$elm$json$Json$Decode$list($author$project$Link$decode)),
		A2(
			$elm$json$Json$Decode$field,
			'sources',
			$elm$json$Json$Decode$list($author$project$Source$decode)),
		A2($elm$json$Json$Decode$field, 'idGenerator', $author$project$IdGenerator$decode));
}();
var $elm$json$Json$Decode$decodeString = _Json_runOnString;
var $elm$core$String$concat = function (strings) {
	return A2($elm$core$String$join, '', strings);
};
var $author$project$Note$getSource = function (note) {
	return $author$project$Note$getInfo(note).bM;
};
var $author$project$Source$getInfo = function (source) {
	var info = source;
	return info;
};
var $author$project$Source$contains = F2(
	function (input, source) {
		var info = $author$project$Source$getInfo(source);
		var has = function (s) {
			return A2(
				$elm$core$String$contains,
				$elm$core$String$toLower(input),
				$elm$core$String$toLower(s));
		};
		return has(info.dO) || (has(info.fX) || has(info.aP));
	});
var $author$project$Slipbox$getSources = F2(
	function (maybeSearch, slipbox) {
		var content = $author$project$Slipbox$getContent(slipbox);
		if (!maybeSearch.$) {
			var search = maybeSearch.a;
			return A2(
				$elm$core$List$filter,
				$author$project$Source$contains(search),
				content.bi);
		} else {
			return content.bi;
		}
	});
var $author$project$Source$getTitle = function (source) {
	return $author$project$Source$getInfo(source).dO;
};
var $elm$core$List$intersperse = F2(
	function (sep, xs) {
		if (!xs.b) {
			return _List_Nil;
		} else {
			var hd = xs.a;
			var tl = xs.b;
			var step = F2(
				function (x, rest) {
					return A2(
						$elm$core$List$cons,
						sep,
						A2($elm$core$List$cons, x, rest));
				});
			var spersed = A3($elm$core$List$foldr, step, _List_Nil, tl);
			return A2($elm$core$List$cons, hd, spersed);
		}
	});
var $elm$core$String$replace = F3(
	function (before, after, string) {
		return A2(
			$elm$core$String$join,
			after,
			A2($elm$core$String$split, before, string));
	});
var $author$project$Note$getContent = function (note) {
	return $author$project$Note$getInfo(note).aP;
};
var $author$project$Source$getId = function (source) {
	return $author$project$Source$getInfo(source).cT;
};
var $author$project$Export$toEncodedNote = F2(
	function (sources, note) {
		var maybeSource = $elm$core$List$head(
			A2(
				$elm$core$List$filter,
				function (source) {
					var _v1 = $author$project$SourceTitle$getTitle(
						$author$project$Note$getSource(note));
					if (!_v1.$) {
						var sourceTitle = _v1.a;
						return _Utils_eq(
							$author$project$Source$getTitle(source),
							sourceTitle);
					} else {
						return false;
					}
				},
				sources));
		var sourceString = function () {
			if ($author$project$Note$getVariant(note) === 1) {
				return '';
			} else {
				if (!maybeSource.$) {
					var source = maybeSource.a;
					return 'Source ID: ' + $elm$core$String$fromInt(
						$author$project$Source$getId(source));
				} else {
					return 'No Source';
				}
			}
		}();
		return $elm$core$String$concat(
			A2(
				$elm$core$List$intersperse,
				'\n',
				_List_fromArray(
					[
						$author$project$Note$getContent(note),
						sourceString
					])));
	});
var $author$project$Source$getAuthor = function (source) {
	return $author$project$Source$getInfo(source).fX;
};
var $author$project$Source$getContent = function (source) {
	return $author$project$Source$getInfo(source).aP;
};
var $author$project$Export$toEncodedSource = function (source) {
	return $elm$core$String$concat(
		A2(
			$elm$core$List$intersperse,
			'\n',
			_List_fromArray(
				[
					'ID: ' + $elm$core$String$fromInt(
					$author$project$Source$getId(source)),
					'Title: ' + $author$project$Source$getTitle(source),
					'Author: ' + $author$project$Source$getAuthor(source),
					'Content: ' + $author$project$Source$getContent(source)
				])));
};
var $author$project$Export$encode = F2(
	function (slipbox, _export) {
		if (_export.$ === 3) {
			var title = _export.a;
			var notes = _export.b;
			var relevantSources = A2(
				$elm$core$List$filter,
				function (source) {
					return A2(
						$elm$core$List$any,
						function (note) {
							var _v1 = $author$project$SourceTitle$getTitle(
								$author$project$Note$getSource(note));
							if (!_v1.$) {
								var sourceTitle = _v1.a;
								return _Utils_eq(
									sourceTitle,
									$author$project$Source$getTitle(source));
							} else {
								return false;
							}
						},
						notes);
				},
				A2($author$project$Slipbox$getSources, $elm$core$Maybe$Nothing, slipbox));
			var fileTitle = A3($elm$core$String$replace, ' ', '_', title) + '.txt';
			return $elm$core$Maybe$Just(
				_Utils_Tuple2(
					fileTitle,
					$elm$core$String$concat(
						A2(
							$elm$core$List$intersperse,
							'\n\n',
							$elm$core$List$concat(
								_List_fromArray(
									[
										_List_fromArray(
										[title]),
										_List_fromArray(
										['Notes']),
										A2(
										$elm$core$List$map,
										$author$project$Export$toEncodedNote(relevantSources),
										notes),
										_List_fromArray(
										['Sources']),
										A2($elm$core$List$map, $author$project$Export$toEncodedSource, relevantSources)
									]))))));
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $author$project$IdGenerator$getId = function (idGenerator) {
	var id = idGenerator;
	return id;
};
var $elm$json$Json$Encode$int = _Json_wrap;
var $author$project$IdGenerator$encode = function (idGenerator) {
	return $elm$json$Json$Encode$int(
		$author$project$IdGenerator$getId(idGenerator));
};
var $elm$json$Json$Encode$object = function (pairs) {
	return _Json_wrap(
		A3(
			$elm$core$List$foldl,
			F2(
				function (_v0, obj) {
					var k = _v0.a;
					var v = _v0.b;
					return A3(_Json_addField, k, v, obj);
				}),
			_Json_emptyObject(0),
			pairs));
};
var $author$project$Link$encode = function (link) {
	var info = $author$project$Link$getInfo(link);
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'id',
				$elm$json$Json$Encode$int(info.cT)),
				_Utils_Tuple2(
				'sourceId',
				$elm$json$Json$Encode$int(info.dI)),
				_Utils_Tuple2(
				'targetId',
				$elm$json$Json$Encode$int(info.dL))
			]));
};
var $author$project$SourceTitle$encode = function (st) {
	if (!st.$) {
		var title = st.a;
		return title;
	} else {
		return $author$project$SourceTitle$noSourceEncoding;
	}
};
var $elm$json$Json$Encode$string = _Json_wrap;
var $author$project$Note$variantStringRepresentation = function (variant) {
	if (!variant) {
		return 'regular';
	} else {
		return 'index';
	}
};
var $author$project$Note$encode = function (note) {
	var info = $author$project$Note$getInfo(note);
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'id',
				$elm$json$Json$Encode$int(info.cT)),
				_Utils_Tuple2(
				'content',
				$elm$json$Json$Encode$string(info.aP)),
				_Utils_Tuple2(
				'source',
				$elm$json$Json$Encode$string(
					$author$project$SourceTitle$encode(info.bM))),
				_Utils_Tuple2(
				'variant',
				$elm$json$Json$Encode$string(
					$author$project$Note$variantStringRepresentation(info.bo)))
			]));
};
var $author$project$Source$encode = function (source) {
	var info = $author$project$Source$getInfo(source);
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'id',
				$elm$json$Json$Encode$int(info.cT)),
				_Utils_Tuple2(
				'title',
				$elm$json$Json$Encode$string(info.dO)),
				_Utils_Tuple2(
				'author',
				$elm$json$Json$Encode$string(info.fX)),
				_Utils_Tuple2(
				'content',
				$elm$json$Json$Encode$string(info.aP))
			]));
};
var $elm$json$Json$Encode$list = F2(
	function (func, entries) {
		return _Json_wrap(
			A3(
				$elm$core$List$foldl,
				_Json_addEntry(func),
				_Json_emptyArray(0),
				entries));
	});
var $author$project$Slipbox$encode = function (slipbox) {
	var info = $author$project$Slipbox$getContent(slipbox);
	return A2(
		$elm$json$Json$Encode$encode,
		0,
		$elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'notes',
					A2($elm$json$Json$Encode$list, $author$project$Note$encode, info.R)),
					_Utils_Tuple2(
					'links',
					A2($elm$json$Json$Encode$list, $author$project$Link$encode, info.gT)),
					_Utils_Tuple2(
					'sources',
					A2($elm$json$Json$Encode$list, $author$project$Source$encode, info.bi)),
					_Utils_Tuple2(
					'idGenerator',
					$author$project$IdGenerator$encode(info.ae))
				])));
};
var $author$project$Main$getCreate = function (model) {
	if (model.$ === 2) {
		var content = model.a;
		var _v1 = content.l;
		if (_v1.$ === 1) {
			var create = _v1.a;
			return $elm$core$Maybe$Just(create);
		} else {
			return $elm$core$Maybe$Nothing;
		}
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $author$project$Main$getDiscovery = function (model) {
	if (model.$ === 2) {
		var content = model.a;
		var _v1 = content.l;
		if (_v1.$ === 2) {
			var create = _v1.a;
			return $elm$core$Maybe$Just(create);
		} else {
			return $elm$core$Maybe$Nothing;
		}
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $author$project$Main$getEdit = function (model) {
	if (model.$ === 2) {
		var content = model.a;
		var _v1 = content.l;
		if (!_v1.$) {
			var create = _v1.a;
			return $elm$core$Maybe$Just(create);
		} else {
			return $elm$core$Maybe$Nothing;
		}
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $author$project$Main$getExport = function (model) {
	if (model.$ === 2) {
		var content = model.a;
		var _v1 = content.l;
		if (_v1.$ === 3) {
			var _export = _v1.a;
			return $elm$core$Maybe$Just(_export);
		} else {
			return $elm$core$Maybe$Nothing;
		}
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $author$project$Main$getSlipbox = function (model) {
	if (model.$ === 2) {
		var content = model.a;
		return $elm$core$Maybe$Just(content.Y);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $author$project$Create$hover = F2(
	function (note, create) {
		if (create.$ === 2) {
			var coachingModal = create.a;
			var graph = create.b;
			var createModeInternal = create.c;
			var question = create.d;
			var selectedNote = create.e;
			return A6(
				$author$project$Create$FindLinksForDiscussion,
				coachingModal,
				graph,
				createModeInternal,
				question,
				selectedNote,
				$elm$core$Maybe$Just(note));
		} else {
			return create;
		}
	});
var $author$project$Discovery$ViewDiscussion = F4(
	function (a, b, c, d) {
		return {$: 0, a: a, b: b, c: c, d: d};
	});
var $author$project$Discovery$hover = F2(
	function (note, discovery) {
		if (!discovery.$) {
			var discussion = discovery.a;
			var selectedNote = discovery.b;
			var graph = discovery.c;
			return A4(
				$author$project$Discovery$ViewDiscussion,
				discussion,
				selectedNote,
				graph,
				$elm$core$Maybe$Just(note));
		} else {
			return discovery;
		}
	});
var $author$project$Edit$AddLinkDiscussionChosen = F6(
	function (a, b, c, d, e, f) {
		return {$: 5, a: a, b: b, c: c, d: d, e: e, f: f};
	});
var $author$project$Edit$ConfirmBreakLink = F5(
	function (a, b, c, d, e) {
		return {$: 3, a: a, b: b, c: c, d: d, e: e};
	});
var $author$project$Edit$hover = F2(
	function (note, edit) {
		switch (edit.$) {
			case 3:
				var pn = edit.a;
				var link = edit.b;
				var graph = edit.c;
				var selectedNote = edit.d;
				return A5(
					$author$project$Edit$ConfirmBreakLink,
					pn,
					link,
					graph,
					selectedNote,
					$elm$core$Maybe$Just(note));
			case 5:
				var pn = edit.a;
				var discussion = edit.b;
				var graph = edit.c;
				var selectedNote = edit.d;
				var notesToLink = edit.f;
				return A6(
					$author$project$Edit$AddLinkDiscussionChosen,
					pn,
					discussion,
					graph,
					selectedNote,
					$elm$core$Maybe$Just(note),
					notesToLink);
			default:
				return edit;
		}
	});
var $author$project$Create$CoachingModalClosed = 1;
var $author$project$Create$NoteInput = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $author$project$Create$None = {$: 0};
var $author$project$Create$createModeInternalInit = A5($author$project$Create$CreateModeInternal, '', _List_Nil, _List_Nil, $author$project$Create$None, $elm$core$Maybe$Nothing);
var $author$project$Create$init = A2($author$project$Create$NoteInput, 1, $author$project$Create$createModeInternalInit);
var $author$project$Edit$SelectNote = function (a) {
	return {$: 0, a: a};
};
var $author$project$Edit$init = $author$project$Edit$SelectNote('');
var $author$project$IdGenerator$init = 0;
var $author$project$Slipbox$new = A5($author$project$Slipbox$Content, _List_Nil, _List_Nil, _List_Nil, $author$project$IdGenerator$init, false);
var $author$project$Main$newContent = A3(
	$author$project$Main$Content,
	$author$project$Main$CreateModeTab($author$project$Create$init),
	$author$project$Slipbox$new,
	0);
var $author$project$Create$CreateNewSource = F5(
	function (a, b, c, d, e) {
		return {$: 5, a: a, b: b, c: c, d: d, e: e};
	});
var $author$project$Create$newSource = function (create) {
	if (create.$ === 4) {
		var coachingModal = create.a;
		var internal = create.b;
		return A5($author$project$Create$CreateNewSource, coachingModal, internal, '', '', '');
	} else {
		return create;
	}
};
var $author$project$Create$ChooseDiscussion = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $author$project$Create$ChooseSourceCategory = F3(
	function (a, b, c) {
		return {$: 4, a: a, b: b, c: c};
	});
var $author$project$Create$DesignateDiscussionEntryPoint = F3(
	function (a, b, c) {
		return {$: 3, a: a, b: b, c: c};
	});
var $author$project$Create$next = function (create) {
	switch (create.$) {
		case 0:
			var coachingModal = create.a;
			var createModeInternal = create.b;
			return A2($author$project$Create$ChooseDiscussion, coachingModal, createModeInternal);
		case 1:
			var coachingModal = create.a;
			var createModeInternal = create.b;
			return A3($author$project$Create$DesignateDiscussionEntryPoint, coachingModal, createModeInternal, '');
		case 3:
			var coachingModal = create.a;
			var createModeInternal = create.b;
			return A3($author$project$Create$ChooseSourceCategory, coachingModal, createModeInternal, '');
		default:
			return create;
	}
};
var $author$project$Create$PromptCreateAnother = function (a) {
	return {$: 6, a: a};
};
var $author$project$Note$create = F2(
	function (generator, record) {
		var _v0 = $author$project$IdGenerator$generateId(generator);
		var id = _v0.a;
		var idGenerator = _v0.b;
		return _Utils_Tuple2(
			A4(
				$author$project$Note$note_,
				id,
				record.aP,
				record.fp,
				$author$project$Note$variantStringRepresentation(record.bo)),
			idGenerator);
	});
var $author$project$Slipbox$addDiscussion = F2(
	function (discussion, slipbox) {
		var source = 'n/a';
		var content = $author$project$Slipbox$getContent(slipbox);
		var _v0 = A2(
			$author$project$Note$create,
			content.ae,
			{aP: discussion, fp: source, bo: 1});
		var note = _v0.a;
		var idGenerator = _v0.b;
		return _Utils_Tuple2(
			_Utils_update(
				content,
				{
					ae: idGenerator,
					R: A2($elm$core$List$cons, note, content.R),
					aJ: true
				}),
			note);
	});
var $author$project$Slipbox$addNote = F3(
	function (noteContent, sourceTitle, slipbox) {
		var source = $elm$core$String$isEmpty(sourceTitle) ? 'n/a' : sourceTitle;
		var content = $author$project$Slipbox$getContent(slipbox);
		var _v0 = A2(
			$author$project$Note$create,
			content.ae,
			{aP: noteContent, fp: source, bo: 0});
		var note = _v0.a;
		var idGenerator = _v0.b;
		return _Utils_Tuple2(
			_Utils_update(
				content,
				{
					ae: idGenerator,
					R: A2($elm$core$List$cons, note, content.R),
					aJ: true
				}),
			note);
	});
var $author$project$Source$createSource = F2(
	function (generator, content) {
		var _v0 = $author$project$IdGenerator$generateId(generator);
		var id = _v0.a;
		var idGenerator = _v0.b;
		var info = A4($author$project$Source$Info, id, content.dO, content.fX, content.aP);
		return _Utils_Tuple2(info, idGenerator);
	});
var $author$project$Slipbox$addSource = F4(
	function (title, author, sourceContent, slipbox) {
		var content = $author$project$Slipbox$getContent(slipbox);
		var _v0 = A2(
			$author$project$Source$createSource,
			content.ae,
			{fX: author, aP: sourceContent, dO: title});
		var source = _v0.a;
		var generator = _v0.b;
		return _Utils_update(
			content,
			{
				ae: generator,
				bi: A2($elm$core$List$cons, source, content.bi),
				aJ: true
			});
	});
var $author$project$Create$getDiscussion = function (internal) {
	var linkedDiscussion = internal.e;
	return linkedDiscussion;
};
var $author$project$Create$getInternal = function (create) {
	switch (create.$) {
		case 0:
			var createModeInternal = create.b;
			return createModeInternal;
		case 1:
			var createModeInternal = create.b;
			return createModeInternal;
		case 2:
			var createModeInternal = create.c;
			return createModeInternal;
		case 3:
			var createModeInternal = create.b;
			return createModeInternal;
		case 4:
			var createModeInternal = create.b;
			return createModeInternal;
		case 5:
			var createModeInternal = create.b;
			return createModeInternal;
		default:
			var createModeInternal = create.a;
			return createModeInternal;
	}
};
var $author$project$Create$getNote = function (internal) {
	var note = internal.a;
	return note;
};
var $author$project$Create$getSource = function (internal) {
	var source = internal.d;
	return source;
};
var $author$project$Create$updateSlipboxWithLink = F3(
	function (note, link, slipbox) {
		var noteToLink = link;
		return A3($author$project$Slipbox$addLink, note, noteToLink, slipbox);
	});
var $author$project$Create$updateSlipbox = F2(
	function (create, slipbox) {
		var internal = $author$project$Create$getInternal(create);
		var _v0 = function () {
			var _v1 = $author$project$Create$getSource(internal);
			switch (_v1.$) {
				case 0:
					return _Utils_Tuple2('n/a', slipbox);
				case 2:
					var source = _v1.a;
					return _Utils_Tuple2(
						$author$project$Source$getTitle(source),
						slipbox);
				default:
					var title = _v1.a;
					var author = _v1.b;
					var content = _v1.c;
					return _Utils_Tuple2(
						title,
						A4($author$project$Slipbox$addSource, title, author, content, slipbox));
			}
		}();
		var sourceTitle = _v0.a;
		var slipboxWithSource = _v0.b;
		var _v2 = A3(
			$author$project$Slipbox$addNote,
			$author$project$Create$getNote(internal),
			sourceTitle,
			slipboxWithSource);
		var slipboxWithNote = _v2.a;
		var note = _v2.b;
		var updatedSlipbox = function () {
			var _v3 = $author$project$Create$getDiscussion(internal);
			if (!_v3.$) {
				var discussion = _v3.a;
				var _v4 = A2($author$project$Slipbox$addDiscussion, discussion, slipboxWithNote);
				var slipboxWithDiscussion = _v4.a;
				var discussionNote = _v4.b;
				return A3($author$project$Slipbox$addLink, note, discussionNote, slipboxWithDiscussion);
			} else {
				return slipboxWithNote;
			}
		}();
		return A3(
			$elm$core$List$foldr,
			$author$project$Create$updateSlipboxWithLink(note),
			updatedSlipbox,
			$author$project$Create$getCreatedLinks(internal));
	});
var $author$project$Create$noSource = F2(
	function (slipbox, create) {
		if (create.$ === 4) {
			var internal = create.b;
			return _Utils_Tuple2(
				A2($author$project$Create$updateSlipbox, create, slipbox),
				$author$project$Create$PromptCreateAnother(internal));
		} else {
			return _Utils_Tuple2(slipbox, create);
		}
	});
var $author$project$Main$open = _Platform_outgoingPort(
	'open',
	function ($) {
		return $elm$json$Json$Encode$null;
	});
var $author$project$Export$remove = F2(
	function (note, _export) {
		if (_export.$ === 3) {
			var title = _export.a;
			var notes = _export.b;
			return A2(
				$author$project$Export$ConfigureContent,
				title,
				A2(
					$elm$core$List$filter,
					function (n) {
						return !A2($author$project$Note$is, note, n);
					},
					notes));
		} else {
			return _export;
		}
	});
var $author$project$Create$removeLink = function (create) {
	if (create.$ === 2) {
		var coachingModal = create.a;
		var graph = create.b;
		var createModeInternal = create.c;
		var question = create.d;
		var selectedNote = create.e;
		var hoveredNote = create.f;
		var updatedLinks = A2(
			$elm$core$List$filter,
			function (l) {
				return !A2($author$project$Create$linkIsForNote, selectedNote, l);
			},
			$author$project$Create$getCreatedLinks(createModeInternal));
		var updatedInternal = A2($author$project$Create$setCreatedLinks, updatedLinks, createModeInternal);
		return A6($author$project$Create$FindLinksForDiscussion, coachingModal, graph, updatedInternal, question, selectedNote, hoveredNote);
	} else {
		return create;
	}
};
var $author$project$Main$save = _Platform_outgoingPort('save', $elm$json$Json$Encode$string);
var $author$project$Slipbox$saveChanges = function (slipbox) {
	var content = slipbox;
	return _Utils_update(
		content,
		{aJ: false});
};
var $author$project$Edit$DiscussionSelected = function (a) {
	return {$: 2, a: a};
};
var $author$project$Edit$select = function (note) {
	var _v0 = $author$project$Note$getVariant(note);
	if (!_v0) {
		return $author$project$Edit$NoteSelected(note);
	} else {
		return $author$project$Edit$DiscussionSelected(note);
	}
};
var $author$project$Create$selectNote = F2(
	function (note, create) {
		if (create.$ === 2) {
			var coachingModal = create.a;
			var graph = create.b;
			var createModeInternal = create.c;
			var question = create.d;
			var hoveredNote = create.f;
			return A6($author$project$Create$FindLinksForDiscussion, coachingModal, graph, createModeInternal, question, note, hoveredNote);
		} else {
			return create;
		}
	});
var $author$project$Discovery$selectNote = F2(
	function (note, discovery) {
		if (!discovery.$) {
			var discussion = discovery.a;
			var graph = discovery.c;
			var hoverNote = discovery.d;
			return A4($author$project$Discovery$ViewDiscussion, discussion, note, graph, hoverNote);
		} else {
			return discovery;
		}
	});
var $author$project$Edit$selectNoteOnGraph = F2(
	function (note, edit) {
		if (edit.$ === 3) {
			var pn = edit.a;
			var link = edit.b;
			var graph = edit.c;
			var hoveredNote = edit.e;
			return A5($author$project$Edit$ConfirmBreakLink, pn, link, graph, note, hoveredNote);
		} else {
			return edit;
		}
	});
var $author$project$Create$Existing = function (a) {
	return {$: 2, a: a};
};
var $author$project$Create$setExistingSource = F2(
	function (source, internal) {
		var note = internal.a;
		var questionsRead = internal.b;
		var linksCreated = internal.c;
		var discussion = internal.e;
		return A5(
			$author$project$Create$CreateModeInternal,
			note,
			questionsRead,
			linksCreated,
			$author$project$Create$Existing(source),
			discussion);
	});
var $author$project$Create$selectSource = F3(
	function (source, slipbox, create) {
		if (create.$ === 4) {
			var internal = create.b;
			var updatedCreate = $author$project$Create$PromptCreateAnother(
				A2($author$project$Create$setExistingSource, source, internal));
			return _Utils_Tuple2(
				A2($author$project$Create$updateSlipbox, updatedCreate, slipbox),
				updatedCreate);
		} else {
			return _Utils_Tuple2(slipbox, create);
		}
	});
var $author$project$Main$setCreate = F2(
	function (create, model) {
		if (model.$ === 2) {
			var content = model.a;
			var _v1 = content.l;
			if (_v1.$ === 1) {
				return $author$project$Main$Session(
					_Utils_update(
						content,
						{
							l: $author$project$Main$CreateModeTab(create)
						}));
			} else {
				return model;
			}
		} else {
			return model;
		}
	});
var $author$project$Main$setDiscovery = F2(
	function (create, model) {
		if (model.$ === 2) {
			var content = model.a;
			var _v1 = content.l;
			if (_v1.$ === 2) {
				return $author$project$Main$Session(
					_Utils_update(
						content,
						{
							l: $author$project$Main$DiscoveryModeTab(create)
						}));
			} else {
				return model;
			}
		} else {
			return model;
		}
	});
var $author$project$Main$setEdit = F2(
	function (create, model) {
		if (model.$ === 2) {
			var content = model.a;
			var _v1 = content.l;
			if (!_v1.$) {
				return $author$project$Main$Session(
					_Utils_update(
						content,
						{
							l: $author$project$Main$EditModeTab(create)
						}));
			} else {
				return model;
			}
		} else {
			return model;
		}
	});
var $author$project$Main$setExport = F2(
	function (_export, model) {
		if (model.$ === 2) {
			var content = model.a;
			var _v1 = content.l;
			if (_v1.$ === 3) {
				return $author$project$Main$Session(
					_Utils_update(
						content,
						{
							l: $author$project$Main$ExportModeTab(_export)
						}));
			} else {
				return model;
			}
		} else {
			return model;
		}
	});
var $author$project$Main$setSlipbox = F2(
	function (slipbox, model) {
		if (model.$ === 2) {
			var content = model.a;
			return $author$project$Main$Session(
				_Utils_update(
					content,
					{Y: slipbox}));
		} else {
			return model;
		}
	});
var $author$project$Main$setTab = F2(
	function (tab, model) {
		if (model.$ === 2) {
			var content = model.a;
			return $author$project$Main$Session(
				_Utils_update(
					content,
					{l: tab}));
		} else {
			return model;
		}
	});
var $author$project$Discovery$DesignateDiscussionEntryPoint = F2(
	function (a, b) {
		return {$: 2, a: a, b: b};
	});
var $author$project$Discovery$startNewDiscussion = function (discovery) {
	if (!discovery.$) {
		var selectedNote = discovery.b;
		return A2($author$project$Discovery$DesignateDiscussionEntryPoint, selectedNote, '');
	} else {
		return discovery;
	}
};
var $author$project$Create$stopHover = function (create) {
	if (create.$ === 2) {
		var coachingModal = create.a;
		var graph = create.b;
		var createModeInternal = create.c;
		var question = create.d;
		var selectedNote = create.e;
		return A6($author$project$Create$FindLinksForDiscussion, coachingModal, graph, createModeInternal, question, selectedNote, $elm$core$Maybe$Nothing);
	} else {
		return create;
	}
};
var $author$project$Discovery$stopHover = function (discovery) {
	if (!discovery.$) {
		var discussion = discovery.a;
		var selectedNote = discovery.b;
		var graph = discovery.c;
		return A4($author$project$Discovery$ViewDiscussion, discussion, selectedNote, graph, $elm$core$Maybe$Nothing);
	} else {
		return discovery;
	}
};
var $author$project$Edit$stopHover = function (edit) {
	switch (edit.$) {
		case 3:
			var pn = edit.a;
			var link = edit.b;
			var graph = edit.c;
			var selectedNote = edit.d;
			return A5($author$project$Edit$ConfirmBreakLink, pn, link, graph, selectedNote, $elm$core$Maybe$Nothing);
		case 5:
			var pn = edit.a;
			var discussion = edit.b;
			var graph = edit.c;
			var selectedNote = edit.d;
			var notesToLink = edit.f;
			return A6($author$project$Edit$AddLinkDiscussionChosen, pn, discussion, graph, selectedNote, $elm$core$Maybe$Nothing, notesToLink);
		default:
			return edit;
	}
};
var $elm$time$Time$Posix = $elm$core$Basics$identity;
var $elm$time$Time$millisToPosix = $elm$core$Basics$identity;
var $elm$file$File$Download$string = F3(
	function (name, mime, content) {
		return A2(
			$elm$core$Task$perform,
			$elm$core$Basics$never,
			A3(_File_download, name, mime, content));
	});
var $author$project$Graph$Graph = F2(
	function (positions, links) {
		return {gT: links, hf: positions};
	});
var $gampleman$elm_visualization$Force$Center = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $gampleman$elm_visualization$Force$center = $gampleman$elm_visualization$Force$Center;
var $gampleman$elm_visualization$Force$isCompleted = function (_v0) {
	var alpha = _v0.a4;
	var minAlpha = _v0.da;
	return _Utils_cmp(alpha, minAlpha) < 1;
};
var $gampleman$elm_visualization$Force$State = $elm$core$Basics$identity;
var $elm$core$Basics$compare = _Utils_compare;
var $elm$core$Dict$get = F2(
	function (targetKey, dict) {
		get:
		while (true) {
			if (dict.$ === -2) {
				return $elm$core$Maybe$Nothing;
			} else {
				var key = dict.b;
				var value = dict.c;
				var left = dict.d;
				var right = dict.e;
				var _v1 = A2($elm$core$Basics$compare, targetKey, key);
				switch (_v1) {
					case 0:
						var $temp$targetKey = targetKey,
							$temp$dict = left;
						targetKey = $temp$targetKey;
						dict = $temp$dict;
						continue get;
					case 1:
						return $elm$core$Maybe$Just(value);
					default:
						var $temp$targetKey = targetKey,
							$temp$dict = right;
						targetKey = $temp$targetKey;
						dict = $temp$dict;
						continue get;
				}
			}
		}
	});
var $elm$core$Dict$RBEmpty_elm_builtin = {$: -2};
var $elm$core$Dict$RBNode_elm_builtin = F5(
	function (a, b, c, d, e) {
		return {$: -1, a: a, b: b, c: c, d: d, e: e};
	});
var $elm$core$Dict$map = F2(
	function (func, dict) {
		if (dict.$ === -2) {
			return $elm$core$Dict$RBEmpty_elm_builtin;
		} else {
			var color = dict.a;
			var key = dict.b;
			var value = dict.c;
			var left = dict.d;
			var right = dict.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				color,
				key,
				A2(func, key, value),
				A2($elm$core$Dict$map, func, left),
				A2($elm$core$Dict$map, func, right));
		}
	});
var $elm$core$Maybe$map = F2(
	function (f, maybe) {
		if (!maybe.$) {
			var value = maybe.a;
			return $elm$core$Maybe$Just(
				f(value));
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $gampleman$elm_visualization$Force$nTimes = F3(
	function (fn, times, input) {
		nTimes:
		while (true) {
			if (times <= 0) {
				return input;
			} else {
				var $temp$fn = fn,
					$temp$times = times - 1,
					$temp$input = fn(input);
				fn = $temp$fn;
				times = $temp$times;
				input = $temp$input;
				continue nTimes;
			}
		}
	});
var $elm$core$Basics$pow = _Basics_pow;
var $elm$core$Dict$sizeHelp = F2(
	function (n, dict) {
		sizeHelp:
		while (true) {
			if (dict.$ === -2) {
				return n;
			} else {
				var left = dict.d;
				var right = dict.e;
				var $temp$n = A2($elm$core$Dict$sizeHelp, n + 1, right),
					$temp$dict = left;
				n = $temp$n;
				dict = $temp$dict;
				continue sizeHelp;
			}
		}
	});
var $elm$core$Dict$size = function (dict) {
	return A2($elm$core$Dict$sizeHelp, 0, dict);
};
var $elm$core$Basics$sqrt = _Basics_sqrt;
var $elm$core$Dict$Black = 1;
var $elm$core$Dict$Red = 0;
var $elm$core$Dict$balance = F5(
	function (color, key, value, left, right) {
		if ((right.$ === -1) && (!right.a)) {
			var _v1 = right.a;
			var rK = right.b;
			var rV = right.c;
			var rLeft = right.d;
			var rRight = right.e;
			if ((left.$ === -1) && (!left.a)) {
				var _v3 = left.a;
				var lK = left.b;
				var lV = left.c;
				var lLeft = left.d;
				var lRight = left.e;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					0,
					key,
					value,
					A5($elm$core$Dict$RBNode_elm_builtin, 1, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 1, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					color,
					rK,
					rV,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, key, value, left, rLeft),
					rRight);
			}
		} else {
			if ((((left.$ === -1) && (!left.a)) && (left.d.$ === -1)) && (!left.d.a)) {
				var _v5 = left.a;
				var lK = left.b;
				var lV = left.c;
				var _v6 = left.d;
				var _v7 = _v6.a;
				var llK = _v6.b;
				var llV = _v6.c;
				var llLeft = _v6.d;
				var llRight = _v6.e;
				var lRight = left.e;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					0,
					lK,
					lV,
					A5($elm$core$Dict$RBNode_elm_builtin, 1, llK, llV, llLeft, llRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 1, key, value, lRight, right));
			} else {
				return A5($elm$core$Dict$RBNode_elm_builtin, color, key, value, left, right);
			}
		}
	});
var $elm$core$Dict$insertHelp = F3(
	function (key, value, dict) {
		if (dict.$ === -2) {
			return A5($elm$core$Dict$RBNode_elm_builtin, 0, key, value, $elm$core$Dict$RBEmpty_elm_builtin, $elm$core$Dict$RBEmpty_elm_builtin);
		} else {
			var nColor = dict.a;
			var nKey = dict.b;
			var nValue = dict.c;
			var nLeft = dict.d;
			var nRight = dict.e;
			var _v1 = A2($elm$core$Basics$compare, key, nKey);
			switch (_v1) {
				case 0:
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						A3($elm$core$Dict$insertHelp, key, value, nLeft),
						nRight);
				case 1:
					return A5($elm$core$Dict$RBNode_elm_builtin, nColor, nKey, value, nLeft, nRight);
				default:
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						nLeft,
						A3($elm$core$Dict$insertHelp, key, value, nRight));
			}
		}
	});
var $elm$core$Dict$insert = F3(
	function (key, value, dict) {
		var _v0 = A3($elm$core$Dict$insertHelp, key, value, dict);
		if ((_v0.$ === -1) && (!_v0.a)) {
			var _v1 = _v0.a;
			var k = _v0.b;
			var v = _v0.c;
			var l = _v0.d;
			var r = _v0.e;
			return A5($elm$core$Dict$RBNode_elm_builtin, 1, k, v, l, r);
		} else {
			var x = _v0;
			return x;
		}
	});
var $elm$core$Dict$getMin = function (dict) {
	getMin:
	while (true) {
		if ((dict.$ === -1) && (dict.d.$ === -1)) {
			var left = dict.d;
			var $temp$dict = left;
			dict = $temp$dict;
			continue getMin;
		} else {
			return dict;
		}
	}
};
var $elm$core$Dict$moveRedLeft = function (dict) {
	if (((dict.$ === -1) && (dict.d.$ === -1)) && (dict.e.$ === -1)) {
		if ((dict.e.d.$ === -1) && (!dict.e.d.a)) {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v1 = dict.d;
			var lClr = _v1.a;
			var lK = _v1.b;
			var lV = _v1.c;
			var lLeft = _v1.d;
			var lRight = _v1.e;
			var _v2 = dict.e;
			var rClr = _v2.a;
			var rK = _v2.b;
			var rV = _v2.c;
			var rLeft = _v2.d;
			var _v3 = rLeft.a;
			var rlK = rLeft.b;
			var rlV = rLeft.c;
			var rlL = rLeft.d;
			var rlR = rLeft.e;
			var rRight = _v2.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				0,
				rlK,
				rlV,
				A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, lK, lV, lLeft, lRight),
					rlL),
				A5($elm$core$Dict$RBNode_elm_builtin, 1, rK, rV, rlR, rRight));
		} else {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v4 = dict.d;
			var lClr = _v4.a;
			var lK = _v4.b;
			var lV = _v4.c;
			var lLeft = _v4.d;
			var lRight = _v4.e;
			var _v5 = dict.e;
			var rClr = _v5.a;
			var rK = _v5.b;
			var rV = _v5.c;
			var rLeft = _v5.d;
			var rRight = _v5.e;
			if (clr === 1) {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 0, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 0, rK, rV, rLeft, rRight));
			}
		}
	} else {
		return dict;
	}
};
var $elm$core$Dict$moveRedRight = function (dict) {
	if (((dict.$ === -1) && (dict.d.$ === -1)) && (dict.e.$ === -1)) {
		if ((dict.d.d.$ === -1) && (!dict.d.d.a)) {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v1 = dict.d;
			var lClr = _v1.a;
			var lK = _v1.b;
			var lV = _v1.c;
			var _v2 = _v1.d;
			var _v3 = _v2.a;
			var llK = _v2.b;
			var llV = _v2.c;
			var llLeft = _v2.d;
			var llRight = _v2.e;
			var lRight = _v1.e;
			var _v4 = dict.e;
			var rClr = _v4.a;
			var rK = _v4.b;
			var rV = _v4.c;
			var rLeft = _v4.d;
			var rRight = _v4.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				0,
				lK,
				lV,
				A5($elm$core$Dict$RBNode_elm_builtin, 1, llK, llV, llLeft, llRight),
				A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					lRight,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, rK, rV, rLeft, rRight)));
		} else {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v5 = dict.d;
			var lClr = _v5.a;
			var lK = _v5.b;
			var lV = _v5.c;
			var lLeft = _v5.d;
			var lRight = _v5.e;
			var _v6 = dict.e;
			var rClr = _v6.a;
			var rK = _v6.b;
			var rV = _v6.c;
			var rLeft = _v6.d;
			var rRight = _v6.e;
			if (clr === 1) {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 0, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 0, rK, rV, rLeft, rRight));
			}
		}
	} else {
		return dict;
	}
};
var $elm$core$Dict$removeHelpPrepEQGT = F7(
	function (targetKey, dict, color, key, value, left, right) {
		if ((left.$ === -1) && (!left.a)) {
			var _v1 = left.a;
			var lK = left.b;
			var lV = left.c;
			var lLeft = left.d;
			var lRight = left.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				color,
				lK,
				lV,
				lLeft,
				A5($elm$core$Dict$RBNode_elm_builtin, 0, key, value, lRight, right));
		} else {
			_v2$2:
			while (true) {
				if ((right.$ === -1) && (right.a === 1)) {
					if (right.d.$ === -1) {
						if (right.d.a === 1) {
							var _v3 = right.a;
							var _v4 = right.d;
							var _v5 = _v4.a;
							return $elm$core$Dict$moveRedRight(dict);
						} else {
							break _v2$2;
						}
					} else {
						var _v6 = right.a;
						var _v7 = right.d;
						return $elm$core$Dict$moveRedRight(dict);
					}
				} else {
					break _v2$2;
				}
			}
			return dict;
		}
	});
var $elm$core$Dict$removeMin = function (dict) {
	if ((dict.$ === -1) && (dict.d.$ === -1)) {
		var color = dict.a;
		var key = dict.b;
		var value = dict.c;
		var left = dict.d;
		var lColor = left.a;
		var lLeft = left.d;
		var right = dict.e;
		if (lColor === 1) {
			if ((lLeft.$ === -1) && (!lLeft.a)) {
				var _v3 = lLeft.a;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					color,
					key,
					value,
					$elm$core$Dict$removeMin(left),
					right);
			} else {
				var _v4 = $elm$core$Dict$moveRedLeft(dict);
				if (_v4.$ === -1) {
					var nColor = _v4.a;
					var nKey = _v4.b;
					var nValue = _v4.c;
					var nLeft = _v4.d;
					var nRight = _v4.e;
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						$elm$core$Dict$removeMin(nLeft),
						nRight);
				} else {
					return $elm$core$Dict$RBEmpty_elm_builtin;
				}
			}
		} else {
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				color,
				key,
				value,
				$elm$core$Dict$removeMin(left),
				right);
		}
	} else {
		return $elm$core$Dict$RBEmpty_elm_builtin;
	}
};
var $elm$core$Dict$removeHelp = F2(
	function (targetKey, dict) {
		if (dict.$ === -2) {
			return $elm$core$Dict$RBEmpty_elm_builtin;
		} else {
			var color = dict.a;
			var key = dict.b;
			var value = dict.c;
			var left = dict.d;
			var right = dict.e;
			if (_Utils_cmp(targetKey, key) < 0) {
				if ((left.$ === -1) && (left.a === 1)) {
					var _v4 = left.a;
					var lLeft = left.d;
					if ((lLeft.$ === -1) && (!lLeft.a)) {
						var _v6 = lLeft.a;
						return A5(
							$elm$core$Dict$RBNode_elm_builtin,
							color,
							key,
							value,
							A2($elm$core$Dict$removeHelp, targetKey, left),
							right);
					} else {
						var _v7 = $elm$core$Dict$moveRedLeft(dict);
						if (_v7.$ === -1) {
							var nColor = _v7.a;
							var nKey = _v7.b;
							var nValue = _v7.c;
							var nLeft = _v7.d;
							var nRight = _v7.e;
							return A5(
								$elm$core$Dict$balance,
								nColor,
								nKey,
								nValue,
								A2($elm$core$Dict$removeHelp, targetKey, nLeft),
								nRight);
						} else {
							return $elm$core$Dict$RBEmpty_elm_builtin;
						}
					}
				} else {
					return A5(
						$elm$core$Dict$RBNode_elm_builtin,
						color,
						key,
						value,
						A2($elm$core$Dict$removeHelp, targetKey, left),
						right);
				}
			} else {
				return A2(
					$elm$core$Dict$removeHelpEQGT,
					targetKey,
					A7($elm$core$Dict$removeHelpPrepEQGT, targetKey, dict, color, key, value, left, right));
			}
		}
	});
var $elm$core$Dict$removeHelpEQGT = F2(
	function (targetKey, dict) {
		if (dict.$ === -1) {
			var color = dict.a;
			var key = dict.b;
			var value = dict.c;
			var left = dict.d;
			var right = dict.e;
			if (_Utils_eq(targetKey, key)) {
				var _v1 = $elm$core$Dict$getMin(right);
				if (_v1.$ === -1) {
					var minKey = _v1.b;
					var minValue = _v1.c;
					return A5(
						$elm$core$Dict$balance,
						color,
						minKey,
						minValue,
						left,
						$elm$core$Dict$removeMin(right));
				} else {
					return $elm$core$Dict$RBEmpty_elm_builtin;
				}
			} else {
				return A5(
					$elm$core$Dict$balance,
					color,
					key,
					value,
					left,
					A2($elm$core$Dict$removeHelp, targetKey, right));
			}
		} else {
			return $elm$core$Dict$RBEmpty_elm_builtin;
		}
	});
var $elm$core$Dict$remove = F2(
	function (key, dict) {
		var _v0 = A2($elm$core$Dict$removeHelp, key, dict);
		if ((_v0.$ === -1) && (!_v0.a)) {
			var _v1 = _v0.a;
			var k = _v0.b;
			var v = _v0.c;
			var l = _v0.d;
			var r = _v0.e;
			return A5($elm$core$Dict$RBNode_elm_builtin, 1, k, v, l, r);
		} else {
			var x = _v0;
			return x;
		}
	});
var $elm$core$Dict$update = F3(
	function (targetKey, alter, dictionary) {
		var _v0 = alter(
			A2($elm$core$Dict$get, targetKey, dictionary));
		if (!_v0.$) {
			var value = _v0.a;
			return A3($elm$core$Dict$insert, targetKey, value, dictionary);
		} else {
			return A2($elm$core$Dict$remove, targetKey, dictionary);
		}
	});
var $ianmackenzie$elm_geometry$Vector2d$components = function (_v0) {
	var components_ = _v0;
	return components_;
};
var $ianmackenzie$elm_geometry$Geometry$Types$Point2d = $elm$core$Basics$identity;
var $ianmackenzie$elm_geometry$Point2d$fromCoordinates = $elm$core$Basics$identity;
var $ianmackenzie$elm_geometry$BoundingBox2d$maxX = function (_v0) {
	var boundingBox = _v0;
	return boundingBox.eP;
};
var $ianmackenzie$elm_geometry$BoundingBox2d$maxY = function (_v0) {
	var boundingBox = _v0;
	return boundingBox.eQ;
};
var $ianmackenzie$elm_geometry$BoundingBox2d$minX = function (_v0) {
	var boundingBox = _v0;
	return boundingBox.bb;
};
var $ianmackenzie$elm_geometry$BoundingBox2d$minY = function (_v0) {
	var boundingBox = _v0;
	return boundingBox.bc;
};
var $ianmackenzie$elm_geometry$BoundingBox2d$dimensions = function (boundingBox) {
	return _Utils_Tuple2(
		$ianmackenzie$elm_geometry$BoundingBox2d$maxX(boundingBox) - $ianmackenzie$elm_geometry$BoundingBox2d$minX(boundingBox),
		$ianmackenzie$elm_geometry$BoundingBox2d$maxY(boundingBox) - $ianmackenzie$elm_geometry$BoundingBox2d$minY(boundingBox));
};
var $ianmackenzie$elm_geometry$Bootstrap$Point2d$coordinates = function (_v0) {
	var coordinates_ = _v0;
	return coordinates_;
};
var $ianmackenzie$elm_geometry$Geometry$Types$Vector2d = $elm$core$Basics$identity;
var $ianmackenzie$elm_geometry$Vector2d$fromComponents = $elm$core$Basics$identity;
var $ianmackenzie$elm_geometry$Vector2d$from = F2(
	function (firstPoint, secondPoint) {
		var _v0 = $ianmackenzie$elm_geometry$Bootstrap$Point2d$coordinates(secondPoint);
		var x2 = _v0.a;
		var y2 = _v0.b;
		var _v1 = $ianmackenzie$elm_geometry$Bootstrap$Point2d$coordinates(firstPoint);
		var x1 = _v1.a;
		var y1 = _v1.b;
		return $ianmackenzie$elm_geometry$Vector2d$fromComponents(
			_Utils_Tuple2(x2 - x1, y2 - y1));
	});
var $ianmackenzie$elm_geometry$Vector2d$squaredLength = function (vector) {
	var _v0 = $ianmackenzie$elm_geometry$Vector2d$components(vector);
	var x = _v0.a;
	var y = _v0.b;
	return (x * x) + (y * y);
};
var $ianmackenzie$elm_geometry$Point2d$squaredDistanceFrom = F2(
	function (firstPoint, secondPoint) {
		return $ianmackenzie$elm_geometry$Vector2d$squaredLength(
			A2($ianmackenzie$elm_geometry$Vector2d$from, firstPoint, secondPoint));
	});
var $ianmackenzie$elm_geometry$Point2d$distanceFrom = F2(
	function (firstPoint, secondPoint) {
		return $elm$core$Basics$sqrt(
			A2($ianmackenzie$elm_geometry$Point2d$squaredDistanceFrom, firstPoint, secondPoint));
	});
var $elm$core$Basics$isNaN = _Basics_isNaN;
var $ianmackenzie$elm_geometry$Vector2d$scaleBy = F2(
	function (scale, vector) {
		var _v0 = $ianmackenzie$elm_geometry$Vector2d$components(vector);
		var x = _v0.a;
		var y = _v0.b;
		return $ianmackenzie$elm_geometry$Vector2d$fromComponents(
			_Utils_Tuple2(x * scale, y * scale));
	});
var $ianmackenzie$elm_geometry$Vector2d$sum = F2(
	function (firstVector, secondVector) {
		var _v0 = $ianmackenzie$elm_geometry$Vector2d$components(secondVector);
		var x2 = _v0.a;
		var y2 = _v0.b;
		var _v1 = $ianmackenzie$elm_geometry$Vector2d$components(firstVector);
		var x1 = _v1.a;
		var y1 = _v1.b;
		return $ianmackenzie$elm_geometry$Vector2d$fromComponents(
			_Utils_Tuple2(x1 + x2, y1 + y2));
	});
var $ianmackenzie$elm_geometry$Vector2d$zero = $ianmackenzie$elm_geometry$Vector2d$fromComponents(
	_Utils_Tuple2(0, 0));
var $gampleman$elm_visualization$Force$ManyBody$applyForce = F4(
	function (alpha, theta, qtree, vertex) {
		var isFarAway = function (treePart) {
			var distance = A2($ianmackenzie$elm_geometry$Point2d$distanceFrom, vertex.he, treePart.d5.he);
			var _v2 = $ianmackenzie$elm_geometry$BoundingBox2d$dimensions(treePart.f6);
			var width = _v2.a;
			return _Utils_cmp(width / distance, theta) < 0;
		};
		var calculateVelocity = F2(
			function (target, source) {
				var delta = A2($ianmackenzie$elm_geometry$Vector2d$from, target.he, source.he);
				var weight = (source.bk * alpha) / $ianmackenzie$elm_geometry$Vector2d$squaredLength(delta);
				return $elm$core$Basics$isNaN(weight) ? $ianmackenzie$elm_geometry$Vector2d$zero : A2($ianmackenzie$elm_geometry$Vector2d$scaleBy, weight, delta);
			});
		var useAggregate = function (treePart) {
			return A2(calculateVelocity, vertex, treePart.d5);
		};
		switch (qtree.$) {
			case 0:
				return $ianmackenzie$elm_geometry$Vector2d$zero;
			case 1:
				var leaf = qtree.a;
				if (isFarAway(leaf)) {
					return useAggregate(leaf);
				} else {
					var applyForceFromPoint = F2(
						function (point, accum) {
							return _Utils_eq(point.eH, vertex.eH) ? accum : A2(
								$ianmackenzie$elm_geometry$Vector2d$sum,
								A2(calculateVelocity, vertex, point),
								accum);
						});
					var _v1 = leaf.ga;
					var first = _v1.a;
					var rest = _v1.b;
					return A3(
						$elm$core$List$foldl,
						applyForceFromPoint,
						$ianmackenzie$elm_geometry$Vector2d$zero,
						A2($elm$core$List$cons, first, rest));
				}
			default:
				var node = qtree.a;
				if (isFarAway(node)) {
					return useAggregate(node);
				} else {
					var helper = function (tree) {
						return A4($gampleman$elm_visualization$Force$ManyBody$applyForce, alpha, theta, tree, vertex);
					};
					return A2(
						$ianmackenzie$elm_geometry$Vector2d$sum,
						helper(node.hL),
						A2(
							$ianmackenzie$elm_geometry$Vector2d$sum,
							helper(node.hu),
							A2(
								$ianmackenzie$elm_geometry$Vector2d$sum,
								helper(node.g_),
								helper(node.g1))));
				}
		}
	});
var $ianmackenzie$elm_geometry$Point2d$coordinates = function (_v0) {
	var coordinates_ = _v0;
	return coordinates_;
};
var $gampleman$elm_visualization$Force$ManyBody$constructSuperPoint = F2(
	function (first, rest) {
		var initialStrength = first.bk;
		var initialPoint = $ianmackenzie$elm_geometry$Point2d$coordinates(first.he);
		var folder = F2(
			function (point, _v3) {
				var _v4 = _v3.a;
				var accumX = _v4.a;
				var accumY = _v4.b;
				var strength = _v3.b;
				var size = _v3.c;
				var _v2 = $ianmackenzie$elm_geometry$Point2d$coordinates(point.he);
				var x = _v2.a;
				var y = _v2.b;
				return _Utils_Tuple3(
					_Utils_Tuple2(accumX + x, accumY + y),
					strength + point.bk,
					size + 1);
			});
		var _v0 = A3(
			$elm$core$List$foldl,
			folder,
			_Utils_Tuple3(initialPoint, initialStrength, 1),
			rest);
		var _v1 = _v0.a;
		var totalX = _v1.a;
		var totalY = _v1.b;
		var totalStrength = _v0.b;
		var totalSize = _v0.c;
		return {
			he: $ianmackenzie$elm_geometry$Point2d$fromCoordinates(
				_Utils_Tuple2(totalX / totalSize, totalY / totalSize)),
			bk: totalStrength
		};
	});
var $gampleman$elm_visualization$Force$ManyBody$config = {
	ge: $gampleman$elm_visualization$Force$ManyBody$constructSuperPoint,
	gf: $gampleman$elm_visualization$Force$ManyBody$constructSuperPoint,
	h4: function ($) {
		return $.he;
	}
};
var $gampleman$elm_visualization$Force$QuadTree$Empty = {$: 0};
var $gampleman$elm_visualization$Force$QuadTree$empty = $gampleman$elm_visualization$Force$QuadTree$Empty;
var $gampleman$elm_visualization$Force$QuadTree$Leaf = function (a) {
	return {$: 1, a: a};
};
var $gampleman$elm_visualization$Force$QuadTree$Node = function (a) {
	return {$: 2, a: a};
};
var $ianmackenzie$elm_geometry$BoundingBox2d$contains = F2(
	function (point, boundingBox) {
		var _v0 = $ianmackenzie$elm_geometry$Point2d$coordinates(point);
		var x = _v0.a;
		var y = _v0.b;
		return ((_Utils_cmp(
			$ianmackenzie$elm_geometry$BoundingBox2d$minX(boundingBox),
			x) < 1) && (_Utils_cmp(
			x,
			$ianmackenzie$elm_geometry$BoundingBox2d$maxX(boundingBox)) < 1)) && ((_Utils_cmp(
			$ianmackenzie$elm_geometry$BoundingBox2d$minY(boundingBox),
			y) < 1) && (_Utils_cmp(
			y,
			$ianmackenzie$elm_geometry$BoundingBox2d$maxY(boundingBox)) < 1));
	});
var $ianmackenzie$elm_geometry$BoundingBox2d$extrema = function (_v0) {
	var extrema_ = _v0;
	return extrema_;
};
var $ianmackenzie$elm_geometry$Geometry$Types$BoundingBox2d = $elm$core$Basics$identity;
var $elm$core$Basics$min = F2(
	function (x, y) {
		return (_Utils_cmp(x, y) < 0) ? x : y;
	});
var $ianmackenzie$elm_geometry$BoundingBox2d$fromExtrema = function (extrema_) {
	return ((_Utils_cmp(extrema_.bb, extrema_.eP) < 1) && (_Utils_cmp(extrema_.bc, extrema_.eQ) < 1)) ? extrema_ : {
		eP: A2($elm$core$Basics$max, extrema_.bb, extrema_.eP),
		eQ: A2($elm$core$Basics$max, extrema_.bc, extrema_.eQ),
		bb: A2($elm$core$Basics$min, extrema_.bb, extrema_.eP),
		bc: A2($elm$core$Basics$min, extrema_.bc, extrema_.eQ)
	};
};
var $elm$core$Basics$ge = _Utils_ge;
var $ianmackenzie$elm_geometry$BoundingBox2d$hull = F2(
	function (firstBox, secondBox) {
		return $ianmackenzie$elm_geometry$BoundingBox2d$fromExtrema(
			{
				eP: A2(
					$elm$core$Basics$max,
					$ianmackenzie$elm_geometry$BoundingBox2d$maxX(firstBox),
					$ianmackenzie$elm_geometry$BoundingBox2d$maxX(secondBox)),
				eQ: A2(
					$elm$core$Basics$max,
					$ianmackenzie$elm_geometry$BoundingBox2d$maxY(firstBox),
					$ianmackenzie$elm_geometry$BoundingBox2d$maxY(secondBox)),
				bb: A2(
					$elm$core$Basics$min,
					$ianmackenzie$elm_geometry$BoundingBox2d$minX(firstBox),
					$ianmackenzie$elm_geometry$BoundingBox2d$minX(secondBox)),
				bc: A2(
					$elm$core$Basics$min,
					$ianmackenzie$elm_geometry$BoundingBox2d$minY(firstBox),
					$ianmackenzie$elm_geometry$BoundingBox2d$minY(secondBox))
			});
	});
var $gampleman$elm_visualization$Force$QuadTree$NE = 0;
var $gampleman$elm_visualization$Force$QuadTree$NW = 1;
var $gampleman$elm_visualization$Force$QuadTree$SE = 2;
var $gampleman$elm_visualization$Force$QuadTree$SW = 3;
var $ianmackenzie$elm_geometry$BoundingBox2d$midX = function (_v0) {
	var boundingBox = _v0;
	return boundingBox.bb + (0.5 * (boundingBox.eP - boundingBox.bb));
};
var $ianmackenzie$elm_geometry$BoundingBox2d$midY = function (_v0) {
	var boundingBox = _v0;
	return boundingBox.bc + (0.5 * (boundingBox.eQ - boundingBox.bc));
};
var $ianmackenzie$elm_geometry$BoundingBox2d$centerPoint = function (boundingBox) {
	return $ianmackenzie$elm_geometry$Point2d$fromCoordinates(
		_Utils_Tuple2(
			$ianmackenzie$elm_geometry$BoundingBox2d$midX(boundingBox),
			$ianmackenzie$elm_geometry$BoundingBox2d$midY(boundingBox)));
};
var $ianmackenzie$elm_geometry$BoundingBox2d$centroid = function (boundingBox) {
	return $ianmackenzie$elm_geometry$BoundingBox2d$centerPoint(boundingBox);
};
var $gampleman$elm_visualization$Force$QuadTree$quadrant = F2(
	function (boundingBox, point) {
		var _v0 = $ianmackenzie$elm_geometry$Point2d$coordinates(point);
		var x = _v0.a;
		var y = _v0.b;
		var _v1 = $ianmackenzie$elm_geometry$Point2d$coordinates(
			$ianmackenzie$elm_geometry$BoundingBox2d$centroid(boundingBox));
		var midX = _v1.a;
		var midY = _v1.b;
		var _v2 = $ianmackenzie$elm_geometry$BoundingBox2d$extrema(boundingBox);
		var minX = _v2.bb;
		var minY = _v2.bc;
		var maxX = _v2.eP;
		var maxY = _v2.eQ;
		return (_Utils_cmp(y, midY) > -1) ? ((_Utils_cmp(x, midX) > -1) ? 0 : 1) : ((_Utils_cmp(x, midX) > -1) ? 2 : 3);
	});
var $ianmackenzie$elm_geometry$BoundingBox2d$singleton = function (point) {
	var _v0 = $ianmackenzie$elm_geometry$Point2d$coordinates(point);
	var x = _v0.a;
	var y = _v0.b;
	return $ianmackenzie$elm_geometry$BoundingBox2d$fromExtrema(
		{eP: x, eQ: y, bb: x, bc: y});
};
var $gampleman$elm_visualization$Force$QuadTree$singleton = F2(
	function (toPoint, vertex) {
		return $gampleman$elm_visualization$Force$QuadTree$Leaf(
			{
				d5: 0,
				f6: $ianmackenzie$elm_geometry$BoundingBox2d$singleton(
					toPoint(vertex)),
				ga: _Utils_Tuple2(vertex, _List_Nil)
			});
	});
var $gampleman$elm_visualization$Force$QuadTree$insertBy = F3(
	function (toPoint, vertex, qtree) {
		switch (qtree.$) {
			case 0:
				return $gampleman$elm_visualization$Force$QuadTree$Leaf(
					{
						d5: 0,
						f6: $ianmackenzie$elm_geometry$BoundingBox2d$singleton(
							toPoint(vertex)),
						ga: _Utils_Tuple2(vertex, _List_Nil)
					});
			case 1:
				var leaf = qtree.a;
				var maxSize = 32;
				var _v1 = leaf.ga;
				var first = _v1.a;
				var rest = _v1.b;
				var newSize = 2 + $elm$core$List$length(rest);
				if (_Utils_cmp(newSize, maxSize) > -1) {
					var initial = $gampleman$elm_visualization$Force$QuadTree$Node(
						{
							d5: 0,
							f6: A2(
								$ianmackenzie$elm_geometry$BoundingBox2d$hull,
								leaf.f6,
								$ianmackenzie$elm_geometry$BoundingBox2d$singleton(
									toPoint(vertex))),
							g_: $gampleman$elm_visualization$Force$QuadTree$Empty,
							g1: $gampleman$elm_visualization$Force$QuadTree$Empty,
							hu: $gampleman$elm_visualization$Force$QuadTree$Empty,
							hL: $gampleman$elm_visualization$Force$QuadTree$Empty
						});
					return A3(
						$elm$core$List$foldl,
						$gampleman$elm_visualization$Force$QuadTree$insertBy(toPoint),
						initial,
						A2($elm$core$List$cons, first, rest));
				} else {
					return $gampleman$elm_visualization$Force$QuadTree$Leaf(
						{
							d5: 0,
							f6: A2(
								$ianmackenzie$elm_geometry$BoundingBox2d$hull,
								leaf.f6,
								$ianmackenzie$elm_geometry$BoundingBox2d$singleton(
									toPoint(vertex))),
							ga: _Utils_Tuple2(
								vertex,
								A2($elm$core$List$cons, first, rest))
						});
				}
			default:
				var node = qtree.a;
				var point = toPoint(vertex);
				if (A2($ianmackenzie$elm_geometry$BoundingBox2d$contains, point, node.f6)) {
					var _v2 = A2($gampleman$elm_visualization$Force$QuadTree$quadrant, node.f6, point);
					switch (_v2) {
						case 0:
							return $gampleman$elm_visualization$Force$QuadTree$Node(
								{
									d5: node.d5,
									f6: node.f6,
									g_: A3($gampleman$elm_visualization$Force$QuadTree$insertBy, toPoint, vertex, node.g_),
									g1: node.g1,
									hu: node.hu,
									hL: node.hL
								});
						case 2:
							return $gampleman$elm_visualization$Force$QuadTree$Node(
								{
									d5: node.d5,
									f6: node.f6,
									g_: node.g_,
									g1: node.g1,
									hu: A3($gampleman$elm_visualization$Force$QuadTree$insertBy, toPoint, vertex, node.hu),
									hL: node.hL
								});
						case 1:
							return $gampleman$elm_visualization$Force$QuadTree$Node(
								{
									d5: node.d5,
									f6: node.f6,
									g_: node.g_,
									g1: A3($gampleman$elm_visualization$Force$QuadTree$insertBy, toPoint, vertex, node.g1),
									hu: node.hu,
									hL: node.hL
								});
						default:
							return $gampleman$elm_visualization$Force$QuadTree$Node(
								{
									d5: node.d5,
									f6: node.f6,
									g_: node.g_,
									g1: node.g1,
									hu: node.hu,
									hL: A3($gampleman$elm_visualization$Force$QuadTree$insertBy, toPoint, vertex, node.hL)
								});
					}
				} else {
					var _v3 = $ianmackenzie$elm_geometry$BoundingBox2d$extrema(node.f6);
					var minX = _v3.bb;
					var minY = _v3.bc;
					var maxX = _v3.eP;
					var maxY = _v3.eQ;
					var _v4 = $ianmackenzie$elm_geometry$BoundingBox2d$dimensions(node.f6);
					var width = _v4.a;
					var height = _v4.b;
					var _v5 = A2($gampleman$elm_visualization$Force$QuadTree$quadrant, node.f6, point);
					switch (_v5) {
						case 0:
							return $gampleman$elm_visualization$Force$QuadTree$Node(
								{
									d5: 0,
									f6: $ianmackenzie$elm_geometry$BoundingBox2d$fromExtrema(
										{eP: maxX + width, eQ: maxY + height, bb: minX, bc: minY}),
									g_: A2($gampleman$elm_visualization$Force$QuadTree$singleton, toPoint, vertex),
									g1: $gampleman$elm_visualization$Force$QuadTree$Empty,
									hu: $gampleman$elm_visualization$Force$QuadTree$Empty,
									hL: qtree
								});
						case 2:
							return $gampleman$elm_visualization$Force$QuadTree$Node(
								{
									d5: 0,
									f6: $ianmackenzie$elm_geometry$BoundingBox2d$fromExtrema(
										{eP: maxX + width, eQ: maxY, bb: minX, bc: minY - height}),
									g_: $gampleman$elm_visualization$Force$QuadTree$Empty,
									g1: qtree,
									hu: A2($gampleman$elm_visualization$Force$QuadTree$singleton, toPoint, vertex),
									hL: $gampleman$elm_visualization$Force$QuadTree$Empty
								});
						case 1:
							return $gampleman$elm_visualization$Force$QuadTree$Node(
								{
									d5: 0,
									f6: $ianmackenzie$elm_geometry$BoundingBox2d$fromExtrema(
										{eP: maxX, eQ: maxY + height, bb: minX - width, bc: minY}),
									g_: $gampleman$elm_visualization$Force$QuadTree$Empty,
									g1: A2($gampleman$elm_visualization$Force$QuadTree$singleton, toPoint, vertex),
									hu: qtree,
									hL: $gampleman$elm_visualization$Force$QuadTree$Empty
								});
						default:
							return $gampleman$elm_visualization$Force$QuadTree$Node(
								{
									d5: 0,
									f6: $ianmackenzie$elm_geometry$BoundingBox2d$fromExtrema(
										{eP: maxX, eQ: maxY, bb: minX - width, bc: minY - height}),
									g_: qtree,
									g1: $gampleman$elm_visualization$Force$QuadTree$Empty,
									hu: $gampleman$elm_visualization$Force$QuadTree$Empty,
									hL: A2($gampleman$elm_visualization$Force$QuadTree$singleton, toPoint, vertex)
								});
					}
				}
		}
	});
var $gampleman$elm_visualization$Force$QuadTree$fromList = function (toPoint) {
	return A2(
		$elm$core$List$foldl,
		$gampleman$elm_visualization$Force$QuadTree$insertBy(toPoint),
		$gampleman$elm_visualization$Force$QuadTree$empty);
};
var $gampleman$elm_visualization$Force$QuadTree$getAggregate = function (qtree) {
	switch (qtree.$) {
		case 0:
			return $elm$core$Maybe$Nothing;
		case 1:
			var aggregate = qtree.a.d5;
			return $elm$core$Maybe$Just(aggregate);
		default:
			var aggregate = qtree.a.d5;
			return $elm$core$Maybe$Just(aggregate);
	}
};
var $gampleman$elm_visualization$Force$QuadTree$performAggregate = F2(
	function (config, vanillaQuadTree) {
		var combineAggregates = config.ge;
		var combineVertices = config.gf;
		switch (vanillaQuadTree.$) {
			case 0:
				return $gampleman$elm_visualization$Force$QuadTree$Empty;
			case 1:
				var leaf = vanillaQuadTree.a;
				var _v1 = leaf.ga;
				var first = _v1.a;
				var rest = _v1.b;
				return $gampleman$elm_visualization$Force$QuadTree$Leaf(
					{
						d5: A2(combineVertices, first, rest),
						f6: leaf.f6,
						ga: _Utils_Tuple2(first, rest)
					});
			default:
				var node = vanillaQuadTree.a;
				var newSw = A2($gampleman$elm_visualization$Force$QuadTree$performAggregate, config, node.hL);
				var newSe = A2($gampleman$elm_visualization$Force$QuadTree$performAggregate, config, node.hu);
				var newNw = A2($gampleman$elm_visualization$Force$QuadTree$performAggregate, config, node.g1);
				var newNe = A2($gampleman$elm_visualization$Force$QuadTree$performAggregate, config, node.g_);
				var subresults = A2(
					$elm$core$List$filterMap,
					$gampleman$elm_visualization$Force$QuadTree$getAggregate,
					_List_fromArray(
						[newNw, newSw, newNe, newSe]));
				if (!subresults.b) {
					return $gampleman$elm_visualization$Force$QuadTree$Empty;
				} else {
					var x = subresults.a;
					var xs = subresults.b;
					return $gampleman$elm_visualization$Force$QuadTree$Node(
						{
							d5: A2(combineAggregates, x, xs),
							f6: node.f6,
							g_: newNe,
							g1: newNw,
							hu: newSe,
							hL: newSw
						});
				}
		}
	});
var $gampleman$elm_visualization$Force$ManyBody$manyBody = F3(
	function (alpha, theta, vertices) {
		var withAggregates = A2(
			$gampleman$elm_visualization$Force$QuadTree$performAggregate,
			$gampleman$elm_visualization$Force$ManyBody$config,
			A2(
				$gampleman$elm_visualization$Force$QuadTree$fromList,
				function ($) {
					return $.he;
				},
				vertices));
		var updateVertex = function (vertex) {
			return _Utils_update(
				vertex,
				{
					bW: A2(
						$ianmackenzie$elm_geometry$Vector2d$sum,
						vertex.bW,
						A4($gampleman$elm_visualization$Force$ManyBody$applyForce, alpha, theta, withAggregates, vertex))
				});
		};
		return A2($elm$core$List$map, updateVertex, vertices);
	});
var $elm$core$Maybe$withDefault = F2(
	function (_default, maybe) {
		if (!maybe.$) {
			var value = maybe.a;
			return value;
		} else {
			return _default;
		}
	});
var $gampleman$elm_visualization$Force$ManyBody$wrapper = F4(
	function (alpha, theta, strengths, points) {
		var vertices = A2(
			$elm$core$List$map,
			function (_v2) {
				var key = _v2.a;
				var point = _v2.b;
				var x = point.dZ;
				var y = point.d0;
				var strength = A2(
					$elm$core$Maybe$withDefault,
					0,
					A2($elm$core$Dict$get, key, strengths));
				return {
					eH: key,
					he: $ianmackenzie$elm_geometry$Point2d$fromCoordinates(
						_Utils_Tuple2(x, y)),
					bk: strength,
					bW: $ianmackenzie$elm_geometry$Vector2d$zero
				};
			},
			$elm$core$Dict$toList(points));
		var updater = F2(
			function (newVertex, maybePoint) {
				if (maybePoint.$ === 1) {
					return $elm$core$Maybe$Nothing;
				} else {
					var point = maybePoint.a;
					var _v1 = $ianmackenzie$elm_geometry$Vector2d$components(newVertex.bW);
					var dvx = _v1.a;
					var dvy = _v1.b;
					return $elm$core$Maybe$Just(
						_Utils_update(
							point,
							{dT: point.dT + dvx, dU: point.dU + dvy}));
				}
			});
		var newVertices = A3($gampleman$elm_visualization$Force$ManyBody$manyBody, alpha, theta, vertices);
		var folder = F2(
			function (newVertex, pointsDict) {
				return A3(
					$elm$core$Dict$update,
					newVertex.eH,
					updater(newVertex),
					pointsDict);
			});
		return A3($elm$core$List$foldl, folder, points, newVertices);
	});
var $gampleman$elm_visualization$Force$applyForce = F3(
	function (alpha, force, entities) {
		switch (force.$) {
			case 0:
				var x = force.a;
				var y = force.b;
				var n = $elm$core$Dict$size(entities);
				var _v1 = A3(
					$elm$core$Dict$foldr,
					F3(
						function (_v2, ent, _v3) {
							var sx0 = _v3.a;
							var sy0 = _v3.b;
							return _Utils_Tuple2(sx0 + ent.dZ, sy0 + ent.d0);
						}),
					_Utils_Tuple2(0, 0),
					entities);
				var sumx = _v1.a;
				var sumy = _v1.b;
				var sx = (sumx / n) - x;
				var sy = (sumy / n) - y;
				return A2(
					$elm$core$Dict$map,
					F2(
						function (_v4, ent) {
							return _Utils_update(
								ent,
								{dZ: ent.dZ - sx, d0: ent.d0 - sy});
						}),
					entities);
			case 1:
				var _float = force.a;
				var collisionParamidDict = force.b;
				return entities;
			case 2:
				var iters = force.a;
				var lnks = force.b;
				return A3(
					$gampleman$elm_visualization$Force$nTimes,
					function (entitiesList) {
						return A3(
							$elm$core$List$foldl,
							F2(
								function (_v5, ents) {
									var source = _v5.fp;
									var target = _v5.T;
									var distance = _v5.bz;
									var strength = _v5.bk;
									var bias = _v5.cA;
									var _v6 = _Utils_Tuple2(
										A2($elm$core$Dict$get, source, ents),
										A2($elm$core$Dict$get, target, ents));
									if ((!_v6.a.$) && (!_v6.b.$)) {
										var sourceNode = _v6.a.a;
										var targetNode = _v6.b.a;
										var y = ((targetNode.d0 + targetNode.dU) - sourceNode.d0) - sourceNode.dU;
										var x = ((targetNode.dZ + targetNode.dT) - sourceNode.dZ) - sourceNode.dT;
										var d = $elm$core$Basics$sqrt(
											A2($elm$core$Basics$pow, x, 2) + A2($elm$core$Basics$pow, y, 2));
										var l = (((d - distance) / d) * alpha) * strength;
										return A3(
											$elm$core$Dict$update,
											source,
											$elm$core$Maybe$map(
												function (tn) {
													return _Utils_update(
														tn,
														{dT: tn.dT + ((x * l) * (1 - bias)), dU: tn.dU + ((y * l) * (1 - bias))});
												}),
											A3(
												$elm$core$Dict$update,
												target,
												$elm$core$Maybe$map(
													function (sn) {
														return _Utils_update(
															sn,
															{dT: sn.dT - ((x * l) * bias), dU: sn.dU - ((y * l) * bias)});
													}),
												ents));
									} else {
										var otherwise = _v6;
										return ents;
									}
								}),
							entitiesList,
							lnks);
					},
					iters,
					entities);
			case 3:
				var theta = force.a;
				var entityStrengths = force.b;
				return A4($gampleman$elm_visualization$Force$ManyBody$wrapper, alpha, theta, entityStrengths, entities);
			case 4:
				var directionalParamidDict = force.a;
				return entities;
			default:
				var directionalParamidDict = force.a;
				return entities;
		}
	});
var $elm$core$Dict$empty = $elm$core$Dict$RBEmpty_elm_builtin;
var $elm$core$Dict$values = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, valueList) {
				return A2($elm$core$List$cons, value, valueList);
			}),
		_List_Nil,
		dict);
};
var $gampleman$elm_visualization$Force$tick = F2(
	function (_v0, nodes) {
		var state = _v0;
		var updateEntity = function (ent) {
			return _Utils_update(
				ent,
				{dT: ent.dT * state.bX, dU: ent.dU * state.bX, dZ: ent.dZ + (ent.dT * state.bX), d0: ent.d0 + (ent.dU * state.bX)});
		};
		var dictNodes = A3(
			$elm$core$List$foldl,
			function (node) {
				return A2($elm$core$Dict$insert, node.cT, node);
			},
			$elm$core$Dict$empty,
			nodes);
		var alpha = state.a4 + ((state.d9 - state.a4) * state.cw);
		var newNodes = A3(
			$elm$core$List$foldl,
			$gampleman$elm_visualization$Force$applyForce(alpha),
			dictNodes,
			state.er);
		return _Utils_Tuple2(
			_Utils_update(
				state,
				{a4: alpha}),
			A2(
				$elm$core$List$map,
				updateEntity,
				$elm$core$Dict$values(newNodes)));
	});
var $gampleman$elm_visualization$Force$computeSimulation = F2(
	function (state, entities) {
		computeSimulation:
		while (true) {
			if ($gampleman$elm_visualization$Force$isCompleted(state)) {
				return entities;
			} else {
				var _v0 = A2($gampleman$elm_visualization$Force$tick, state, entities);
				var newState = _v0.a;
				var newEntities = _v0.b;
				var $temp$state = newState,
					$temp$entities = newEntities;
				state = $temp$state;
				entities = $temp$entities;
				continue computeSimulation;
			}
		}
	});
var $elm$core$Basics$cos = _Basics_cos;
var $elm$core$Basics$pi = _Basics_pi;
var $gampleman$elm_visualization$Force$initialAngle = $elm$core$Basics$pi * (3 - $elm$core$Basics$sqrt(5));
var $gampleman$elm_visualization$Force$initialRadius = 10;
var $elm$core$Basics$sin = _Basics_sin;
var $gampleman$elm_visualization$Force$entity = F2(
	function (index, a) {
		var radius = $elm$core$Basics$sqrt(index) * $gampleman$elm_visualization$Force$initialRadius;
		var angle = index * $gampleman$elm_visualization$Force$initialAngle;
		return {
			cT: index,
			ao: a,
			dT: 0.0,
			dU: 0.0,
			dZ: radius * $elm$core$Basics$cos(angle),
			d0: radius * $elm$core$Basics$sin(angle)
		};
	});
var $elm$core$Basics$composeR = F3(
	function (f, g, x) {
		return g(
			f(x));
	});
var $gampleman$elm_visualization$Force$Links = F2(
	function (a, b) {
		return {$: 2, a: a, b: b};
	});
var $elm$core$Basics$composeL = F3(
	function (g, f, x) {
		return g(
			f(x));
	});
var $gampleman$elm_visualization$Force$customLinks = F2(
	function (iters, list) {
		var counts = A3(
			$elm$core$List$foldr,
			F2(
				function (_v1, d) {
					var source = _v1.fp;
					var target = _v1.T;
					return A3(
						$elm$core$Dict$update,
						target,
						A2(
							$elm$core$Basics$composeL,
							A2(
								$elm$core$Basics$composeL,
								$elm$core$Maybe$Just,
								$elm$core$Maybe$withDefault(1)),
							$elm$core$Maybe$map(
								$elm$core$Basics$add(1))),
						A3(
							$elm$core$Dict$update,
							source,
							A2(
								$elm$core$Basics$composeL,
								A2(
									$elm$core$Basics$composeL,
									$elm$core$Maybe$Just,
									$elm$core$Maybe$withDefault(1)),
								$elm$core$Maybe$map(
									$elm$core$Basics$add(1))),
							d));
				}),
			$elm$core$Dict$empty,
			list);
		var count = function (key) {
			return A2(
				$elm$core$Maybe$withDefault,
				0,
				A2($elm$core$Dict$get, key, counts));
		};
		return A2(
			$gampleman$elm_visualization$Force$Links,
			iters,
			A2(
				$elm$core$List$map,
				function (_v0) {
					var source = _v0.fp;
					var target = _v0.T;
					var distance = _v0.bz;
					var strength = _v0.bk;
					return {
						cA: count(source) / (count(source) + count(target)),
						bz: distance,
						fp: source,
						bk: A2(
							$elm$core$Maybe$withDefault,
							1 / A2(
								$elm$core$Basics$min,
								count(source),
								count(target)),
							strength),
						T: target
					};
				},
				list));
	});
var $gampleman$elm_visualization$Force$links = A2(
	$elm$core$Basics$composeR,
	$elm$core$List$map(
		function (_v0) {
			var source = _v0.a;
			var target = _v0.b;
			return {bz: 30, fp: source, bk: $elm$core$Maybe$Nothing, T: target};
		}),
	$gampleman$elm_visualization$Force$customLinks(1));
var $gampleman$elm_visualization$Force$ManyBody = F2(
	function (a, b) {
		return {$: 3, a: a, b: b};
	});
var $elm$core$Dict$fromList = function (assocs) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (_v0, dict) {
				var key = _v0.a;
				var value = _v0.b;
				return A3($elm$core$Dict$insert, key, value, dict);
			}),
		$elm$core$Dict$empty,
		assocs);
};
var $gampleman$elm_visualization$Force$customManyBody = function (theta) {
	return A2(
		$elm$core$Basics$composeR,
		$elm$core$Dict$fromList,
		$gampleman$elm_visualization$Force$ManyBody(theta));
};
var $gampleman$elm_visualization$Force$manyBodyStrength = function (strength) {
	return A2(
		$elm$core$Basics$composeL,
		$gampleman$elm_visualization$Force$customManyBody(0.9),
		$elm$core$List$map(
			function (key) {
				return _Utils_Tuple2(key, strength);
			}));
};
var $elm$core$Basics$negate = function (n) {
	return -n;
};
var $gampleman$elm_visualization$Force$simulation = function (forces) {
	return {
		a4: 1.0,
		cw: 1 - A2($elm$core$Basics$pow, 0.001, 1 / 300),
		d9: 0.0,
		er: forces,
		da: 0.001,
		bX: 0.6
	};
};
var $author$project$Graph$simulatePositions = function (_v0) {
	var notes = _v0.a;
	var links = _v0.b;
	var toEntity = function (note) {
		var id = $author$project$Note$getId(note);
		var init = A2($gampleman$elm_visualization$Force$entity, id, 1);
		return {cT: id, eW: note, dT: init.dT, dU: init.dU, dZ: init.dZ, d0: init.d0};
	};
	var entities = A2($elm$core$List$map, toEntity, notes);
	var state = $gampleman$elm_visualization$Force$simulation(
		_List_fromArray(
			[
				A2(
				$gampleman$elm_visualization$Force$manyBodyStrength,
				-60,
				A2(
					$elm$core$List$map,
					function (n) {
						return n.cT;
					},
					entities)),
				$gampleman$elm_visualization$Force$links(
				A2(
					$elm$core$List$map,
					function (link) {
						return _Utils_Tuple2(
							$author$project$Link$getSourceId(link),
							$author$project$Link$getTargetId(link));
					},
					links)),
				A2($gampleman$elm_visualization$Force$center, 0, 0)
			]));
	var notePositions = A2($gampleman$elm_visualization$Force$computeSimulation, state, entities);
	return A2($author$project$Graph$Graph, notePositions, links);
};
var $author$project$Discovery$viewDiscussion = F3(
	function (discussion, slipbox, _v0) {
		return A4(
			$author$project$Discovery$ViewDiscussion,
			discussion,
			discussion,
			$author$project$Graph$simulatePositions(
				A2($author$project$Slipbox$getDiscussionTreeWithCollapsedDiscussions, discussion, slipbox)),
			$elm$core$Maybe$Nothing);
	});
var $author$project$Discovery$submit = F2(
	function (slipbox, discovery) {
		if (discovery.$ === 2) {
			var selectedNote = discovery.a;
			var discussionInput = discovery.b;
			var _v1 = A2($author$project$Slipbox$addDiscussion, discussionInput, slipbox);
			var slipboxWithNewDiscussion = _v1.a;
			var discussion = _v1.b;
			var newSlipbox = A3($author$project$Slipbox$addLink, discussion, selectedNote, slipboxWithNewDiscussion);
			return _Utils_Tuple2(
				newSlipbox,
				A3($author$project$Discovery$viewDiscussion, discussion, newSlipbox, discovery));
		} else {
			return _Utils_Tuple2(slipbox, discovery);
		}
	});
var $author$project$Create$setDiscussion = F2(
	function (discussion, internal) {
		var note = internal.a;
		var questionsRead = internal.b;
		var linksCreated = internal.c;
		var source = internal.d;
		return A5(
			$author$project$Create$CreateModeInternal,
			note,
			questionsRead,
			linksCreated,
			source,
			$elm$core$Maybe$Just(discussion));
	});
var $author$project$Create$submitNewDiscussion = function (create) {
	if (create.$ === 3) {
		var coachingModal = create.a;
		var internal = create.b;
		var discussion = create.c;
		return A3(
			$author$project$Create$ChooseSourceCategory,
			coachingModal,
			A2($author$project$Create$setDiscussion, discussion, internal),
			'');
	} else {
		return create;
	}
};
var $author$project$Create$New = F3(
	function (a, b, c) {
		return {$: 1, a: a, b: b, c: c};
	});
var $author$project$Create$setNewSource = F4(
	function (title, author, content, internal) {
		var note = internal.a;
		var questionsRead = internal.b;
		var linksCreated = internal.c;
		var discussion = internal.e;
		return A5(
			$author$project$Create$CreateModeInternal,
			note,
			questionsRead,
			linksCreated,
			A3($author$project$Create$New, title, author, content),
			discussion);
	});
var $author$project$Create$submitNewSource = F2(
	function (slipbox, create) {
		if (create.$ === 5) {
			var internal = create.b;
			var title = create.c;
			var author = create.d;
			var content = create.e;
			var updatedCreate = $author$project$Create$PromptCreateAnother(
				A4($author$project$Create$setNewSource, title, author, content, internal));
			return _Utils_Tuple2(
				A2($author$project$Create$updateSlipbox, updatedCreate, slipbox),
				updatedCreate);
		} else {
			return _Utils_Tuple2(slipbox, create);
		}
	});
var $author$project$Create$read = F2(
	function (question, internal) {
		var note = internal.a;
		var questionsRead = internal.b;
		var linksCreated = internal.c;
		var source = internal.d;
		var discussion = internal.e;
		return A5(
			$author$project$Create$CreateModeInternal,
			note,
			A2($elm$core$List$cons, question, questionsRead),
			linksCreated,
			source,
			discussion);
	});
var $author$project$Create$toAddLinkState = F3(
	function (question, slipbox, create) {
		if (create.$ === 1) {
			var coachingModal = create.a;
			var createModeInternal = create.b;
			var updatedInternal = A2($author$project$Create$read, question, createModeInternal);
			return A6(
				$author$project$Create$FindLinksForDiscussion,
				coachingModal,
				$author$project$Graph$simulatePositions(
					A2($author$project$Slipbox$getDiscussionTreeWithCollapsedDiscussions, question, slipbox)),
				updatedInternal,
				question,
				question,
				$elm$core$Maybe$Nothing);
		} else {
			return create;
		}
	});
var $author$project$Create$toChooseDiscussionState = function (create) {
	if (create.$ === 2) {
		var coachingModal = create.a;
		var createModeInternal = create.c;
		return A2($author$project$Create$ChooseDiscussion, coachingModal, createModeInternal);
	} else {
		return create;
	}
};
var $author$project$Edit$toConfirmBreakLink = F3(
	function (note, link, slipbox) {
		return A5(
			$author$project$Edit$ConfirmBreakLink,
			note,
			link,
			$author$project$Graph$simulatePositions(
				A2($author$project$Slipbox$getDiscussionTreeWithCollapsedDiscussions, note, slipbox)),
			note,
			$elm$core$Maybe$Nothing);
	});
var $author$project$Edit$toSelectNote = function (edit) {
	if (!edit.$) {
		return edit;
	} else {
		return $author$project$Edit$SelectNote('');
	}
};
var $author$project$Main$Contracted = 1;
var $author$project$Main$toggle = function (state) {
	if (!state) {
		return 1;
	} else {
		return 0;
	}
};
var $author$project$Create$getCoachingModal = function (model) {
	switch (model.$) {
		case 0:
			var coachingModal = model.a;
			return $elm$core$Maybe$Just(coachingModal);
		case 1:
			var coachingModal = model.a;
			return $elm$core$Maybe$Just(coachingModal);
		case 2:
			var coachingModal = model.a;
			return $elm$core$Maybe$Just(coachingModal);
		case 3:
			var coachingModal = model.a;
			return $elm$core$Maybe$Just(coachingModal);
		case 4:
			var coachingModal = model.a;
			return $elm$core$Maybe$Just(coachingModal);
		case 5:
			var coachingModal = model.a;
			return $elm$core$Maybe$Just(coachingModal);
		default:
			return $elm$core$Maybe$Nothing;
	}
};
var $author$project$Create$setCoachingModal = F2(
	function (coachingModal, model) {
		switch (model.$) {
			case 0:
				var internal = model.b;
				return A2($author$project$Create$NoteInput, coachingModal, internal);
			case 1:
				var internal = model.b;
				return A2($author$project$Create$ChooseDiscussion, coachingModal, internal);
			case 2:
				var graph = model.b;
				var internal = model.c;
				var question = model.d;
				var selectedNote = model.e;
				var hoveredNote = model.f;
				return A6($author$project$Create$FindLinksForDiscussion, coachingModal, graph, internal, question, selectedNote, hoveredNote);
			case 3:
				var createModeInternal = model.b;
				var string = model.c;
				return A3($author$project$Create$DesignateDiscussionEntryPoint, coachingModal, createModeInternal, string);
			case 4:
				var internal = model.b;
				var input = model.c;
				return A3($author$project$Create$ChooseSourceCategory, coachingModal, internal, input);
			case 5:
				var internal = model.b;
				var title = model.c;
				var author = model.d;
				var content = model.e;
				return A5($author$project$Create$CreateNewSource, coachingModal, internal, title, author, content);
			default:
				return model;
		}
	});
var $author$project$Create$CoachingModalOpen = 0;
var $author$project$Create$toggle = function (modal) {
	if (!modal) {
		return 1;
	} else {
		return 0;
	}
};
var $author$project$Create$toggleCoachingModal = function (create) {
	var _v0 = $author$project$Create$getCoachingModal(create);
	if (!_v0.$) {
		var coachingModal = _v0.a;
		return A2(
			$author$project$Create$setCoachingModal,
			$author$project$Create$toggle(coachingModal),
			create);
	} else {
		return create;
	}
};
var $author$project$Export$Selected = function (a) {
	return {$: 0, a: a};
};
var $author$project$Export$toggle = function (discussion) {
	if (!discussion.$) {
		var note = discussion.a;
		return $author$project$Export$Unselected(note);
	} else {
		var note = discussion.a;
		return $author$project$Export$Selected(note);
	}
};
var $author$project$Export$toggleDiscussion = F2(
	function (note, _export) {
		if (_export.$ === 2) {
			var title = _export.a;
			var filter = _export.b;
			var discussions = _export.c;
			var foo = A2(
				$elm$core$List$map,
				function (d) {
					return A2(
						$author$project$Note$is,
						note,
						$author$project$Export$getNote(d)) ? $author$project$Export$toggle(d) : d;
				},
				discussions);
			return A3($author$project$Export$SelectDiscussions, title, filter, foo);
		} else {
			return _export;
		}
	});
var $author$project$Create$setNote = F2(
	function (note, internal) {
		var questionsRead = internal.b;
		var linksCreated = internal.c;
		var source = internal.d;
		var discussion = internal.e;
		return A5($author$project$Create$CreateModeInternal, note, questionsRead, linksCreated, source, discussion);
	});
var $author$project$Create$updateInput = F2(
	function (input, create) {
		switch (input.$) {
			case 0:
				var noteInput = input.a;
				switch (create.$) {
					case 0:
						var coachingModal = create.a;
						var createModeInternal = create.b;
						return A2(
							$author$project$Create$NoteInput,
							coachingModal,
							A2($author$project$Create$setNote, noteInput, createModeInternal));
					case 3:
						var coachingModal = create.a;
						var createModeInternal = create.b;
						return A3($author$project$Create$DesignateDiscussionEntryPoint, coachingModal, createModeInternal, noteInput);
					default:
						return create;
				}
			case 1:
				var title = input.a;
				switch (create.$) {
					case 4:
						var coachingModal = create.a;
						var internal = create.b;
						return A3($author$project$Create$ChooseSourceCategory, coachingModal, internal, title);
					case 5:
						var coachingModal = create.a;
						var internal = create.b;
						var author = create.d;
						var content = create.e;
						return A5($author$project$Create$CreateNewSource, coachingModal, internal, title, author, content);
					default:
						return create;
				}
			case 2:
				var author = input.a;
				if (create.$ === 5) {
					var coachingModal = create.a;
					var internal = create.b;
					var title = create.c;
					var content = create.e;
					return A5($author$project$Create$CreateNewSource, coachingModal, internal, title, author, content);
				} else {
					return create;
				}
			default:
				var content = input.a;
				if (create.$ === 5) {
					var coachingModal = create.a;
					var internal = create.b;
					var title = create.c;
					var author = create.d;
					return A5($author$project$Create$CreateNewSource, coachingModal, internal, title, author, content);
				} else {
					return create;
				}
		}
	});
var $author$project$Discovery$updateInput = F2(
	function (input, discovery) {
		switch (discovery.$) {
			case 1:
				return $author$project$Discovery$ChooseDiscussion(input);
			case 2:
				var note = discovery.a;
				return A2($author$project$Discovery$DesignateDiscussionEntryPoint, note, input);
			default:
				return discovery;
		}
	});
var $author$project$Edit$AddLinkChooseDiscussion = F3(
	function (a, b, c) {
		return {$: 4, a: a, b: b, c: c};
	});
var $author$project$Edit$updateInput = F2(
	function (input, edit) {
		switch (edit.$) {
			case 0:
				return $author$project$Edit$SelectNote(input);
			case 4:
				var psn = edit.b;
				var notesToLink = edit.c;
				return A3($author$project$Edit$AddLinkChooseDiscussion, input, psn, notesToLink);
			default:
				return edit;
		}
	});
var $author$project$Export$updateInput = F2(
	function (input, _export) {
		switch (_export.$) {
			case 1:
				return $author$project$Export$InputProjectTitle(input);
			case 2:
				var title = _export.a;
				var discussions = _export.c;
				return A3($author$project$Export$SelectDiscussions, title, input, discussions);
			default:
				return _export;
		}
	});
var $author$project$Main$update = F2(
	function (message, model) {
		var getAndSetWithSlipboxLambda = F3(
			function (getter, setter, updater) {
				var _v24 = $author$project$Main$getSlipbox(model);
				if (!_v24.$) {
					var slipbox = _v24.a;
					var _v25 = getter(model);
					if (!_v25.$) {
						var create = _v25.a;
						var _v26 = A2(updater, slipbox, create);
						var updatedSlipbox = _v26.a;
						var updatedModule = _v26.b;
						return _Utils_Tuple2(
							A2(
								$author$project$Main$setSlipbox,
								updatedSlipbox,
								A2(setter, updatedModule, model)),
							$author$project$Main$changesMade(0));
					} else {
						return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					}
				} else {
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				}
			});
		var getAndSetLambda = F3(
			function (getter, setter, updater) {
				var _v23 = getter(model);
				if (!_v23.$) {
					var create = _v23.a;
					return _Utils_Tuple2(
						A2(
							setter,
							updater(create),
							model),
						$elm$core$Platform$Cmd$none);
				} else {
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				}
			});
		var exportModeLambda = function (updater) {
			return A3(getAndSetLambda, $author$project$Main$getExport, $author$project$Main$setExport, updater);
		};
		var editModeLambda = function (updater) {
			return A3(getAndSetLambda, $author$project$Main$getEdit, $author$project$Main$setEdit, updater);
		};
		var editModeAndSlipboxLambda = function (updater) {
			return A3(getAndSetWithSlipboxLambda, $author$project$Main$getEdit, $author$project$Main$setEdit, updater);
		};
		var discoveryModeLambda = function (updater) {
			return A3(getAndSetLambda, $author$project$Main$getDiscovery, $author$project$Main$setDiscovery, updater);
		};
		var discoveryModeAndSlipboxLambda = function (updater) {
			return A3(getAndSetWithSlipboxLambda, $author$project$Main$getDiscovery, $author$project$Main$setDiscovery, updater);
		};
		var createModeLambda = function (updater) {
			return A3(getAndSetLambda, $author$project$Main$getCreate, $author$project$Main$setCreate, updater);
		};
		var createModeAndSlipboxLambda = function (updater) {
			return A3(getAndSetWithSlipboxLambda, $author$project$Main$getCreate, $author$project$Main$setCreate, updater);
		};
		switch (message.$) {
			case 0:
				return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
			case 1:
				return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
			case 2:
				if (!model.$) {
					return _Utils_Tuple2(
						$author$project$Main$Session($author$project$Main$newContent),
						$elm$core$Platform$Cmd$none);
				} else {
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				}
			case 3:
				if (!model.$) {
					return _Utils_Tuple2(
						model,
						$author$project$Main$open(0));
				} else {
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				}
			case 4:
				var fileContentAsString = message.a;
				if (!model.$) {
					var maybeSlipbox = A2($elm$json$Json$Decode$decodeString, $author$project$Slipbox$decode, fileContentAsString);
					if (!maybeSlipbox.$) {
						var slipbox = maybeSlipbox.a;
						return _Utils_Tuple2(
							$author$project$Main$Session(
								A3(
									$author$project$Main$Content,
									$author$project$Main$CreateModeTab($author$project$Create$init),
									slipbox,
									0)),
							$elm$core$Platform$Cmd$none);
					} else {
						return _Utils_Tuple2($author$project$Main$FailureToParse, $elm$core$Platform$Cmd$none);
					}
				} else {
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				}
			case 5:
				var _v5 = $author$project$Main$getSlipbox(model);
				if (!_v5.$) {
					var slipbox = _v5.a;
					return _Utils_Tuple2(
						A2(
							$author$project$Main$setSlipbox,
							$author$project$Slipbox$saveChanges(slipbox),
							model),
						$elm$core$Platform$Cmd$none);
				} else {
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				}
			case 6:
				var _v6 = $author$project$Main$getSlipbox(model);
				if (!_v6.$) {
					var slipbox = _v6.a;
					return _Utils_Tuple2(
						model,
						$author$project$Main$save(
							$author$project$Slipbox$encode(slipbox)));
				} else {
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				}
			case 7:
				var tab = message.a;
				if (model.$ === 2) {
					var content = model.a;
					switch (tab) {
						case 0:
							var _v9 = content.l;
							if (!_v9.$) {
								return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
							} else {
								return _Utils_Tuple2(
									$author$project$Main$Session(
										_Utils_update(
											content,
											{
												l: $author$project$Main$EditModeTab($author$project$Edit$init)
											})),
									$elm$core$Platform$Cmd$none);
							}
						case 1:
							var _v10 = content.l;
							if (_v10.$ === 1) {
								return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
							} else {
								return _Utils_Tuple2(
									$author$project$Main$Session(
										_Utils_update(
											content,
											{
												l: $author$project$Main$CreateModeTab($author$project$Create$init)
											})),
									$elm$core$Platform$Cmd$none);
							}
						case 2:
							var _v11 = content.l;
							if (_v11.$ === 2) {
								return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
							} else {
								return _Utils_Tuple2(
									$author$project$Main$Session(
										_Utils_update(
											content,
											{
												l: $author$project$Main$DiscoveryModeTab($author$project$Discovery$init)
											})),
									$elm$core$Platform$Cmd$none);
							}
						default:
							var _v12 = content.l;
							if (_v12.$ === 3) {
								return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
							} else {
								var _v13 = $author$project$Main$getSlipbox(model);
								if (!_v13.$) {
									var slipbox = _v13.a;
									return _Utils_Tuple2(
										$author$project$Main$Session(
											_Utils_update(
												content,
												{
													l: $author$project$Main$ExportModeTab(
														$author$project$Export$init(slipbox))
												})),
										$elm$core$Platform$Cmd$none);
								} else {
									return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
								}
							}
					}
				} else {
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				}
			case 8:
				if (model.$ === 2) {
					var content = model.a;
					return _Utils_Tuple2(
						$author$project$Main$Session(
							_Utils_update(
								content,
								{
									cl: $author$project$Main$toggle(content.cl)
								})),
						$elm$core$Platform$Cmd$none);
				} else {
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				}
			case 9:
				return createModeLambda($author$project$Create$toggleCoachingModal);
			case 10:
				return createModeLambda($author$project$Create$next);
			case 11:
				var discussion = message.a;
				var _v15 = $author$project$Main$getSlipbox(model);
				if (!_v15.$) {
					var slipbox = _v15.a;
					return createModeLambda(
						A2($author$project$Create$toAddLinkState, discussion, slipbox));
				} else {
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				}
			case 12:
				return createModeLambda($author$project$Create$toChooseDiscussionState);
			case 13:
				return createModeLambda($author$project$Create$createLink);
			case 14:
				return createModeLambda($author$project$Create$removeLink);
			case 15:
				var newSelectedNote = message.a;
				return createModeLambda(
					$author$project$Create$selectNote(newSelectedNote));
			case 20:
				var input = message.a;
				return createModeLambda(
					$author$project$Create$updateInput(input));
			case 16:
				var source = message.a;
				return createModeAndSlipboxLambda(
					$author$project$Create$selectSource(source));
			case 17:
				return createModeAndSlipboxLambda($author$project$Create$noSource);
			case 18:
				return createModeLambda($author$project$Create$newSource);
			case 19:
				return createModeAndSlipboxLambda($author$project$Create$submitNewSource);
			case 21:
				return createModeLambda(
					function (c) {
						return $author$project$Create$init;
					});
			case 22:
				return createModeLambda($author$project$Create$submitNewDiscussion);
			case 23:
				var note = message.a;
				return createModeLambda(
					$author$project$Create$hover(note));
			case 24:
				return createModeLambda($author$project$Create$stopHover);
			case 25:
				var input = message.a;
				return discoveryModeLambda(
					$author$project$Discovery$updateInput(input));
			case 26:
				var discussion = message.a;
				var _v16 = $author$project$Main$getSlipbox(model);
				if (!_v16.$) {
					var slipbox = _v16.a;
					return discoveryModeLambda(
						A2($author$project$Discovery$viewDiscussion, discussion, slipbox));
				} else {
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				}
			case 27:
				return discoveryModeLambda($author$project$Discovery$back);
			case 28:
				var note = message.a;
				return discoveryModeLambda(
					$author$project$Discovery$selectNote(note));
			case 29:
				return discoveryModeAndSlipboxLambda($author$project$Discovery$submit);
			case 30:
				return discoveryModeLambda($author$project$Discovery$startNewDiscussion);
			case 31:
				var note = message.a;
				return discoveryModeLambda(
					$author$project$Discovery$hover(note));
			case 32:
				return discoveryModeLambda($author$project$Discovery$stopHover);
			case 33:
				var input = message.a;
				return editModeLambda(
					$author$project$Edit$updateInput(input));
			case 34:
				var note = message.a;
				return _Utils_Tuple2(
					A2(
						$author$project$Main$setTab,
						$author$project$Main$EditModeTab(
							$author$project$Edit$select(note)),
						model),
					$elm$core$Platform$Cmd$none);
			case 35:
				var note = message.a;
				var link = message.b;
				var _v17 = $author$project$Main$getSlipbox(model);
				if (!_v17.$) {
					var slipbox = _v17.a;
					return _Utils_Tuple2(
						A2(
							$author$project$Main$setTab,
							$author$project$Main$EditModeTab(
								A3($author$project$Edit$toConfirmBreakLink, note, link, slipbox)),
							model),
						$elm$core$Platform$Cmd$none);
				} else {
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				}
			case 36:
				var note = message.a;
				return editModeLambda(
					$author$project$Edit$selectNoteOnGraph(note));
			case 37:
				return editModeLambda($author$project$Edit$cancel);
			case 38:
				return editModeAndSlipboxLambda($author$project$Edit$confirm);
			case 39:
				var note = message.a;
				return editModeLambda(
					$author$project$Edit$hover(note));
			case 40:
				return editModeLambda($author$project$Edit$stopHover);
			case 41:
				return editModeLambda($author$project$Edit$toSelectNote);
			case 42:
				var _v18 = $author$project$Main$getSlipbox(model);
				if (!_v18.$) {
					var slipbox = _v18.a;
					return exportModeLambda(
						$author$project$Export$continue(slipbox));
				} else {
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				}
			case 43:
				var input = message.a;
				return exportModeLambda(
					$author$project$Export$updateInput(input));
			case 44:
				var discussion = message.a;
				return exportModeLambda(
					$author$project$Export$toggleDiscussion(discussion));
			case 45:
				var note = message.a;
				return exportModeLambda(
					$author$project$Export$remove(note));
			default:
				var _v19 = $author$project$Main$getSlipbox(model);
				if (!_v19.$) {
					var slipbox = _v19.a;
					var _v20 = $author$project$Main$getExport(model);
					if (!_v20.$) {
						var _export = _v20.a;
						var cmd = function () {
							var _v21 = A2($author$project$Export$encode, slipbox, _export);
							if (!_v21.$) {
								var _v22 = _v21.a;
								var title = _v22.a;
								var file = _v22.b;
								return A3($elm$file$File$Download$string, title, 'text/plain', file);
							} else {
								return $elm$core$Platform$Cmd$none;
							}
						}();
						return _Utils_Tuple2(
							A2(
								$author$project$Main$setExport,
								A2($author$project$Export$continue, slipbox, _export),
								model),
							cmd);
					} else {
						return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					}
				} else {
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				}
		}
	});
var $mdgriffith$elm_ui$Internal$Style$classes = {fJ: 'a', ct: 'atv', fL: 'ab', fM: 'cx', fN: 'cy', fO: 'acb', fP: 'accx', fQ: 'accy', fR: 'acr', d7: 'al', d8: 'ar', fS: 'at', cu: 'ah', cv: 'av', fV: 's', f$: 'bh', f0: 'b', f1: 'w7', f3: 'bd', f4: 'bdt', bZ: 'bn', f5: 'bs', b0: 'cpe', gb: 'cp', gc: 'cpx', gd: 'cpy', av: 'c', b3: 'ctr', b4: 'cb', b5: 'ccx', aw: 'ccy', bv: 'cl', b6: 'cr', gg: 'ct', gi: 'cptr', gj: 'ctxt', gx: 'fcs', eq: 'focus-within', gz: 'fs', gA: 'g', cN: 'hbh', cP: 'hc', ev: 'he', cQ: 'hf', ew: 'hfp', gD: 'hv', gF: 'ic', gH: 'fr', cb: 'lbl', gL: 'iml', gM: 'imlf', gN: 'imlp', gO: 'implw', gP: 'it', gR: 'i', eM: 'lnk', bd: 'nb', eV: 'notxt', g3: 'ol', g4: 'or', aV: 'oq', ha: 'oh', e0: 'pg', e1: 'p', hb: 'ppe', hl: 'ui', fh: 'r', hr: 'sb', hs: 'sbx', ht: 'sby', hv: 'sbt', hy: 'e', hz: 'cap', hA: 'sev', hI: 'sk', hN: 't', hO: 'tc', hP: 'w8', hQ: 'w2', hR: 'w9', hS: 'tj', cn: 'tja', hT: 'tl', hU: 'w3', hV: 'w5', hW: 'w4', hX: 'tr', hY: 'w6', hZ: 'w1', h_: 'tun', V: 'ts', a1: 'clr', h7: 'u', dW: 'wc', fE: 'we', dX: 'wf', fF: 'wfp', dY: 'wrp'};
var $mdgriffith$elm_ui$Internal$Model$Attr = function (a) {
	return {$: 1, a: a};
};
var $elm$html$Html$Attributes$stringProperty = F2(
	function (key, string) {
		return A2(
			_VirtualDom_property,
			key,
			$elm$json$Json$Encode$string(string));
	});
var $elm$html$Html$Attributes$class = $elm$html$Html$Attributes$stringProperty('className');
var $mdgriffith$elm_ui$Internal$Model$htmlClass = function (cls) {
	return $mdgriffith$elm_ui$Internal$Model$Attr(
		$elm$html$Html$Attributes$class(cls));
};
var $mdgriffith$elm_ui$Internal$Model$OnlyDynamic = F2(
	function (a, b) {
		return {$: 2, a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Model$StaticRootAndDynamic = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Model$Unkeyed = function (a) {
	return {$: 0, a: a};
};
var $mdgriffith$elm_ui$Internal$Model$AsEl = 2;
var $mdgriffith$elm_ui$Internal$Model$asEl = 2;
var $mdgriffith$elm_ui$Internal$Model$Generic = {$: 0};
var $mdgriffith$elm_ui$Internal$Model$div = $mdgriffith$elm_ui$Internal$Model$Generic;
var $mdgriffith$elm_ui$Internal$Model$NoNearbyChildren = {$: 0};
var $mdgriffith$elm_ui$Internal$Model$columnClass = $mdgriffith$elm_ui$Internal$Style$classes.fV + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.av);
var $mdgriffith$elm_ui$Internal$Model$gridClass = $mdgriffith$elm_ui$Internal$Style$classes.fV + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.gA);
var $mdgriffith$elm_ui$Internal$Model$pageClass = $mdgriffith$elm_ui$Internal$Style$classes.fV + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.e0);
var $mdgriffith$elm_ui$Internal$Model$paragraphClass = $mdgriffith$elm_ui$Internal$Style$classes.fV + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.e1);
var $mdgriffith$elm_ui$Internal$Model$rowClass = $mdgriffith$elm_ui$Internal$Style$classes.fV + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.fh);
var $mdgriffith$elm_ui$Internal$Model$singleClass = $mdgriffith$elm_ui$Internal$Style$classes.fV + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.hy);
var $mdgriffith$elm_ui$Internal$Model$contextClasses = function (context) {
	switch (context) {
		case 0:
			return $mdgriffith$elm_ui$Internal$Model$rowClass;
		case 1:
			return $mdgriffith$elm_ui$Internal$Model$columnClass;
		case 2:
			return $mdgriffith$elm_ui$Internal$Model$singleClass;
		case 3:
			return $mdgriffith$elm_ui$Internal$Model$gridClass;
		case 4:
			return $mdgriffith$elm_ui$Internal$Model$paragraphClass;
		default:
			return $mdgriffith$elm_ui$Internal$Model$pageClass;
	}
};
var $mdgriffith$elm_ui$Internal$Model$Keyed = function (a) {
	return {$: 1, a: a};
};
var $mdgriffith$elm_ui$Internal$Model$NoStyleSheet = {$: 0};
var $mdgriffith$elm_ui$Internal$Model$Styled = function (a) {
	return {$: 1, a: a};
};
var $mdgriffith$elm_ui$Internal$Model$Unstyled = function (a) {
	return {$: 0, a: a};
};
var $mdgriffith$elm_ui$Internal$Model$addChildren = F2(
	function (existing, nearbyChildren) {
		switch (nearbyChildren.$) {
			case 0:
				return existing;
			case 1:
				var behind = nearbyChildren.a;
				return _Utils_ap(behind, existing);
			case 2:
				var inFront = nearbyChildren.a;
				return _Utils_ap(existing, inFront);
			default:
				var behind = nearbyChildren.a;
				var inFront = nearbyChildren.b;
				return _Utils_ap(
					behind,
					_Utils_ap(existing, inFront));
		}
	});
var $mdgriffith$elm_ui$Internal$Model$addKeyedChildren = F3(
	function (key, existing, nearbyChildren) {
		switch (nearbyChildren.$) {
			case 0:
				return existing;
			case 1:
				var behind = nearbyChildren.a;
				return _Utils_ap(
					A2(
						$elm$core$List$map,
						function (x) {
							return _Utils_Tuple2(key, x);
						},
						behind),
					existing);
			case 2:
				var inFront = nearbyChildren.a;
				return _Utils_ap(
					existing,
					A2(
						$elm$core$List$map,
						function (x) {
							return _Utils_Tuple2(key, x);
						},
						inFront));
			default:
				var behind = nearbyChildren.a;
				var inFront = nearbyChildren.b;
				return _Utils_ap(
					A2(
						$elm$core$List$map,
						function (x) {
							return _Utils_Tuple2(key, x);
						},
						behind),
					_Utils_ap(
						existing,
						A2(
							$elm$core$List$map,
							function (x) {
								return _Utils_Tuple2(key, x);
							},
							inFront)));
		}
	});
var $mdgriffith$elm_ui$Internal$Model$AsParagraph = 4;
var $mdgriffith$elm_ui$Internal$Model$asParagraph = 4;
var $mdgriffith$elm_ui$Internal$Flag$Flag = function (a) {
	return {$: 0, a: a};
};
var $mdgriffith$elm_ui$Internal$Flag$Second = function (a) {
	return {$: 1, a: a};
};
var $elm$core$Bitwise$shiftLeftBy = _Bitwise_shiftLeftBy;
var $mdgriffith$elm_ui$Internal$Flag$flag = function (i) {
	return (i > 31) ? $mdgriffith$elm_ui$Internal$Flag$Second(1 << (i - 32)) : $mdgriffith$elm_ui$Internal$Flag$Flag(1 << i);
};
var $mdgriffith$elm_ui$Internal$Flag$alignBottom = $mdgriffith$elm_ui$Internal$Flag$flag(41);
var $mdgriffith$elm_ui$Internal$Flag$alignRight = $mdgriffith$elm_ui$Internal$Flag$flag(40);
var $mdgriffith$elm_ui$Internal$Flag$centerX = $mdgriffith$elm_ui$Internal$Flag$flag(42);
var $mdgriffith$elm_ui$Internal$Flag$centerY = $mdgriffith$elm_ui$Internal$Flag$flag(43);
var $elm$html$Html$div = _VirtualDom_node('div');
var $elm$core$Set$Set_elm_builtin = $elm$core$Basics$identity;
var $elm$core$Set$empty = $elm$core$Dict$empty;
var $mdgriffith$elm_ui$Internal$Model$lengthClassName = function (x) {
	switch (x.$) {
		case 0:
			var px = x.a;
			return $elm$core$String$fromInt(px) + 'px';
		case 1:
			return 'auto';
		case 2:
			var i = x.a;
			return $elm$core$String$fromInt(i) + 'fr';
		case 3:
			var min = x.a;
			var len = x.b;
			return 'min' + ($elm$core$String$fromInt(min) + $mdgriffith$elm_ui$Internal$Model$lengthClassName(len));
		default:
			var max = x.a;
			var len = x.b;
			return 'max' + ($elm$core$String$fromInt(max) + $mdgriffith$elm_ui$Internal$Model$lengthClassName(len));
	}
};
var $elm$core$Basics$round = _Basics_round;
var $mdgriffith$elm_ui$Internal$Model$floatClass = function (x) {
	return $elm$core$String$fromInt(
		$elm$core$Basics$round(x * 255));
};
var $mdgriffith$elm_ui$Internal$Model$transformClass = function (transform) {
	switch (transform.$) {
		case 0:
			return $elm$core$Maybe$Nothing;
		case 1:
			var _v1 = transform.a;
			var x = _v1.a;
			var y = _v1.b;
			var z = _v1.c;
			return $elm$core$Maybe$Just(
				'mv-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(x) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(y) + ('-' + $mdgriffith$elm_ui$Internal$Model$floatClass(z))))));
		default:
			var _v2 = transform.a;
			var tx = _v2.a;
			var ty = _v2.b;
			var tz = _v2.c;
			var _v3 = transform.b;
			var sx = _v3.a;
			var sy = _v3.b;
			var sz = _v3.c;
			var _v4 = transform.c;
			var ox = _v4.a;
			var oy = _v4.b;
			var oz = _v4.c;
			var angle = transform.d;
			return $elm$core$Maybe$Just(
				'tfrm-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(tx) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(ty) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(tz) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(sx) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(sy) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(sz) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(ox) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(oy) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(oz) + ('-' + $mdgriffith$elm_ui$Internal$Model$floatClass(angle))))))))))))))))))));
	}
};
var $mdgriffith$elm_ui$Internal$Model$getStyleName = function (style) {
	switch (style.$) {
		case 13:
			var name = style.a;
			return name;
		case 12:
			var name = style.a;
			var o = style.b;
			return name;
		case 0:
			var _class = style.a;
			return _class;
		case 1:
			var name = style.a;
			return name;
		case 2:
			var i = style.a;
			return 'font-size-' + $elm$core$String$fromInt(i);
		case 3:
			var _class = style.a;
			return _class;
		case 4:
			var _class = style.a;
			return _class;
		case 5:
			var cls = style.a;
			var x = style.b;
			var y = style.c;
			return cls;
		case 7:
			var cls = style.a;
			var top = style.b;
			var right = style.c;
			var bottom = style.d;
			var left = style.e;
			return cls;
		case 6:
			var cls = style.a;
			var top = style.b;
			var right = style.c;
			var bottom = style.d;
			var left = style.e;
			return cls;
		case 8:
			var template = style.a;
			return 'grid-rows-' + (A2(
				$elm$core$String$join,
				'-',
				A2($elm$core$List$map, $mdgriffith$elm_ui$Internal$Model$lengthClassName, template.hn)) + ('-cols-' + (A2(
				$elm$core$String$join,
				'-',
				A2($elm$core$List$map, $mdgriffith$elm_ui$Internal$Model$lengthClassName, template.b2)) + ('-space-x-' + ($mdgriffith$elm_ui$Internal$Model$lengthClassName(template.hB.a) + ('-space-y-' + $mdgriffith$elm_ui$Internal$Model$lengthClassName(template.hB.b)))))));
		case 9:
			var pos = style.a;
			return 'gp grid-pos-' + ($elm$core$String$fromInt(pos.fh) + ('-' + ($elm$core$String$fromInt(pos.ef) + ('-' + ($elm$core$String$fromInt(pos.aL) + ('-' + $elm$core$String$fromInt(pos.cO)))))));
		case 11:
			var selector = style.a;
			var subStyle = style.b;
			var name = function () {
				switch (selector) {
					case 0:
						return 'fs';
					case 1:
						return 'hv';
					default:
						return 'act';
				}
			}();
			return A2(
				$elm$core$String$join,
				' ',
				A2(
					$elm$core$List$map,
					function (sty) {
						var _v1 = $mdgriffith$elm_ui$Internal$Model$getStyleName(sty);
						if (_v1 === '') {
							return '';
						} else {
							var styleName = _v1;
							return styleName + ('-' + name);
						}
					},
					subStyle));
		default:
			var x = style.a;
			return A2(
				$elm$core$Maybe$withDefault,
				'',
				$mdgriffith$elm_ui$Internal$Model$transformClass(x));
	}
};
var $elm$core$Set$insert = F2(
	function (key, _v0) {
		var dict = _v0;
		return A3($elm$core$Dict$insert, key, 0, dict);
	});
var $elm$core$Dict$member = F2(
	function (key, dict) {
		var _v0 = A2($elm$core$Dict$get, key, dict);
		if (!_v0.$) {
			return true;
		} else {
			return false;
		}
	});
var $elm$core$Set$member = F2(
	function (key, _v0) {
		var dict = _v0;
		return A2($elm$core$Dict$member, key, dict);
	});
var $mdgriffith$elm_ui$Internal$Model$reduceStyles = F2(
	function (style, nevermind) {
		var cache = nevermind.a;
		var existing = nevermind.b;
		var styleName = $mdgriffith$elm_ui$Internal$Model$getStyleName(style);
		return A2($elm$core$Set$member, styleName, cache) ? nevermind : _Utils_Tuple2(
			A2($elm$core$Set$insert, styleName, cache),
			A2($elm$core$List$cons, style, existing));
	});
var $mdgriffith$elm_ui$Internal$Model$Property = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Model$Style = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Style$dot = function (c) {
	return '.' + c;
};
var $elm$core$String$fromFloat = _String_fromNumber;
var $mdgriffith$elm_ui$Internal$Model$formatColor = function (_v0) {
	var red = _v0.a;
	var green = _v0.b;
	var blue = _v0.c;
	var alpha = _v0.d;
	return 'rgba(' + ($elm$core$String$fromInt(
		$elm$core$Basics$round(red * 255)) + ((',' + $elm$core$String$fromInt(
		$elm$core$Basics$round(green * 255))) + ((',' + $elm$core$String$fromInt(
		$elm$core$Basics$round(blue * 255))) + (',' + ($elm$core$String$fromFloat(alpha) + ')')))));
};
var $mdgriffith$elm_ui$Internal$Model$formatBoxShadow = function (shadow) {
	return A2(
		$elm$core$String$join,
		' ',
		A2(
			$elm$core$List$filterMap,
			$elm$core$Basics$identity,
			_List_fromArray(
				[
					shadow.eC ? $elm$core$Maybe$Just('inset') : $elm$core$Maybe$Nothing,
					$elm$core$Maybe$Just(
					$elm$core$String$fromFloat(shadow.b.a) + 'px'),
					$elm$core$Maybe$Just(
					$elm$core$String$fromFloat(shadow.b.b) + 'px'),
					$elm$core$Maybe$Just(
					$elm$core$String$fromFloat(shadow.a5) + 'px'),
					$elm$core$Maybe$Just(
					$elm$core$String$fromFloat(shadow.fn) + 'px'),
					$elm$core$Maybe$Just(
					$mdgriffith$elm_ui$Internal$Model$formatColor(shadow.a6))
				])));
};
var $elm$core$Tuple$mapFirst = F2(
	function (func, _v0) {
		var x = _v0.a;
		var y = _v0.b;
		return _Utils_Tuple2(
			func(x),
			y);
	});
var $elm$core$Tuple$mapSecond = F2(
	function (func, _v0) {
		var x = _v0.a;
		var y = _v0.b;
		return _Utils_Tuple2(
			x,
			func(y));
	});
var $mdgriffith$elm_ui$Internal$Model$renderFocusStyle = function (focus) {
	return _List_fromArray(
		[
			A2(
			$mdgriffith$elm_ui$Internal$Model$Style,
			$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.eq) + ':focus-within',
			A2(
				$elm$core$List$filterMap,
				$elm$core$Basics$identity,
				_List_fromArray(
					[
						A2(
						$elm$core$Maybe$map,
						function (color) {
							return A2(
								$mdgriffith$elm_ui$Internal$Model$Property,
								'border-color',
								$mdgriffith$elm_ui$Internal$Model$formatColor(color));
						},
						focus.f2),
						A2(
						$elm$core$Maybe$map,
						function (color) {
							return A2(
								$mdgriffith$elm_ui$Internal$Model$Property,
								'background-color',
								$mdgriffith$elm_ui$Internal$Model$formatColor(color));
						},
						focus.fZ),
						A2(
						$elm$core$Maybe$map,
						function (shadow) {
							return A2(
								$mdgriffith$elm_ui$Internal$Model$Property,
								'box-shadow',
								$mdgriffith$elm_ui$Internal$Model$formatBoxShadow(
									{
										a5: shadow.a5,
										a6: shadow.a6,
										eC: false,
										b: A2(
											$elm$core$Tuple$mapSecond,
											$elm$core$Basics$toFloat,
											A2($elm$core$Tuple$mapFirst, $elm$core$Basics$toFloat, shadow.b)),
										fn: shadow.fn
									}));
						},
						focus.hx),
						$elm$core$Maybe$Just(
						A2($mdgriffith$elm_ui$Internal$Model$Property, 'outline', 'none'))
					]))),
			A2(
			$mdgriffith$elm_ui$Internal$Model$Style,
			($mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fV) + ':focus .focusable, ') + (($mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fV) + '.focusable:focus, ') + ('.ui-slide-bar:focus + ' + ($mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fV) + ' .focusable-thumb'))),
			A2(
				$elm$core$List$filterMap,
				$elm$core$Basics$identity,
				_List_fromArray(
					[
						A2(
						$elm$core$Maybe$map,
						function (color) {
							return A2(
								$mdgriffith$elm_ui$Internal$Model$Property,
								'border-color',
								$mdgriffith$elm_ui$Internal$Model$formatColor(color));
						},
						focus.f2),
						A2(
						$elm$core$Maybe$map,
						function (color) {
							return A2(
								$mdgriffith$elm_ui$Internal$Model$Property,
								'background-color',
								$mdgriffith$elm_ui$Internal$Model$formatColor(color));
						},
						focus.fZ),
						A2(
						$elm$core$Maybe$map,
						function (shadow) {
							return A2(
								$mdgriffith$elm_ui$Internal$Model$Property,
								'box-shadow',
								$mdgriffith$elm_ui$Internal$Model$formatBoxShadow(
									{
										a5: shadow.a5,
										a6: shadow.a6,
										eC: false,
										b: A2(
											$elm$core$Tuple$mapSecond,
											$elm$core$Basics$toFloat,
											A2($elm$core$Tuple$mapFirst, $elm$core$Basics$toFloat, shadow.b)),
										fn: shadow.fn
									}));
						},
						focus.hx),
						$elm$core$Maybe$Just(
						A2($mdgriffith$elm_ui$Internal$Model$Property, 'outline', 'none'))
					])))
		]);
};
var $elm$virtual_dom$VirtualDom$node = function (tag) {
	return _VirtualDom_node(
		_VirtualDom_noScript(tag));
};
var $elm$virtual_dom$VirtualDom$property = F2(
	function (key, value) {
		return A2(
			_VirtualDom_property,
			_VirtualDom_noInnerHtmlOrFormAction(key),
			_VirtualDom_noJavaScriptOrHtmlUri(value));
	});
var $mdgriffith$elm_ui$Internal$Style$AllChildren = F2(
	function (a, b) {
		return {$: 2, a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Style$Batch = function (a) {
	return {$: 6, a: a};
};
var $mdgriffith$elm_ui$Internal$Style$Child = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Style$Class = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Style$Descriptor = F2(
	function (a, b) {
		return {$: 4, a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Style$Left = 3;
var $mdgriffith$elm_ui$Internal$Style$Prop = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Style$Right = 2;
var $mdgriffith$elm_ui$Internal$Style$Self = $elm$core$Basics$identity;
var $mdgriffith$elm_ui$Internal$Style$Supports = F2(
	function (a, b) {
		return {$: 3, a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Style$Content = $elm$core$Basics$identity;
var $mdgriffith$elm_ui$Internal$Style$Bottom = 1;
var $mdgriffith$elm_ui$Internal$Style$CenterX = 4;
var $mdgriffith$elm_ui$Internal$Style$CenterY = 5;
var $mdgriffith$elm_ui$Internal$Style$Top = 0;
var $mdgriffith$elm_ui$Internal$Style$alignments = _List_fromArray(
	[0, 1, 2, 3, 4, 5]);
var $mdgriffith$elm_ui$Internal$Style$contentName = function (desc) {
	switch (desc) {
		case 0:
			var _v1 = desc;
			return $mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.gg);
		case 1:
			var _v2 = desc;
			return $mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.b4);
		case 2:
			var _v3 = desc;
			return $mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.b6);
		case 3:
			var _v4 = desc;
			return $mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.bv);
		case 4:
			var _v5 = desc;
			return $mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.b5);
		default:
			var _v6 = desc;
			return $mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.aw);
	}
};
var $mdgriffith$elm_ui$Internal$Style$selfName = function (desc) {
	switch (desc) {
		case 0:
			var _v1 = desc;
			return $mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fS);
		case 1:
			var _v2 = desc;
			return $mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fL);
		case 2:
			var _v3 = desc;
			return $mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.d8);
		case 3:
			var _v4 = desc;
			return $mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.d7);
		case 4:
			var _v5 = desc;
			return $mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fM);
		default:
			var _v6 = desc;
			return $mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fN);
	}
};
var $mdgriffith$elm_ui$Internal$Style$describeAlignment = function (values) {
	var createDescription = function (alignment) {
		var _v0 = values(alignment);
		var content = _v0.a;
		var indiv = _v0.b;
		return _List_fromArray(
			[
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$contentName(alignment),
				content),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Child,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fV),
				_List_fromArray(
					[
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$selfName(alignment),
						indiv)
					]))
			]);
	};
	return $mdgriffith$elm_ui$Internal$Style$Batch(
		A2($elm$core$List$concatMap, createDescription, $mdgriffith$elm_ui$Internal$Style$alignments));
};
var $mdgriffith$elm_ui$Internal$Style$elDescription = _List_fromArray(
	[
		A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'flex'),
		A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-direction', 'column'),
		A2($mdgriffith$elm_ui$Internal$Style$Prop, 'white-space', 'pre'),
		A2(
		$mdgriffith$elm_ui$Internal$Style$Descriptor,
		$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.cN),
		_List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'z-index', '0'),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Child,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.f$),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'z-index', '-1')
					]))
			])),
		A2(
		$mdgriffith$elm_ui$Internal$Style$Descriptor,
		$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hv),
		_List_fromArray(
			[
				A2(
				$mdgriffith$elm_ui$Internal$Style$Child,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hN),
				_List_fromArray(
					[
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.cQ),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '0')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.dX),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'auto !important')
							]))
					]))
			])),
		A2(
		$mdgriffith$elm_ui$Internal$Style$Child,
		$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.cP),
		_List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', 'auto')
			])),
		A2(
		$mdgriffith$elm_ui$Internal$Style$Child,
		$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.cQ),
		_List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '100000')
			])),
		A2(
		$mdgriffith$elm_ui$Internal$Style$Child,
		$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.dX),
		_List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%')
			])),
		A2(
		$mdgriffith$elm_ui$Internal$Style$Child,
		$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fF),
		_List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%')
			])),
		A2(
		$mdgriffith$elm_ui$Internal$Style$Child,
		$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.dW),
		_List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'flex-start')
			])),
		$mdgriffith$elm_ui$Internal$Style$describeAlignment(
		function (alignment) {
			switch (alignment) {
				case 0:
					return _Utils_Tuple2(
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'flex-start')
							]),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-bottom', 'auto !important'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-top', '0 !important')
							]));
				case 1:
					return _Utils_Tuple2(
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'flex-end')
							]),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-top', 'auto !important'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-bottom', '0 !important')
							]));
				case 2:
					return _Utils_Tuple2(
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'flex-end')
							]),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'flex-end')
							]));
				case 3:
					return _Utils_Tuple2(
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'flex-start')
							]),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'flex-start')
							]));
				case 4:
					return _Utils_Tuple2(
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'center')
							]),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'center')
							]));
				default:
					return _Utils_Tuple2(
						_List_fromArray(
							[
								A2(
								$mdgriffith$elm_ui$Internal$Style$Child,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fV),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-top', 'auto'),
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-bottom', 'auto')
									]))
							]),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-top', 'auto !important'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-bottom', 'auto !important')
							]));
			}
		})
	]);
var $mdgriffith$elm_ui$Internal$Style$gridAlignments = function (values) {
	var createDescription = function (alignment) {
		return _List_fromArray(
			[
				A2(
				$mdgriffith$elm_ui$Internal$Style$Child,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fV),
				_List_fromArray(
					[
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$selfName(alignment),
						values(alignment))
					]))
			]);
	};
	return $mdgriffith$elm_ui$Internal$Style$Batch(
		A2($elm$core$List$concatMap, createDescription, $mdgriffith$elm_ui$Internal$Style$alignments));
};
var $mdgriffith$elm_ui$Internal$Style$Above = 0;
var $mdgriffith$elm_ui$Internal$Style$Behind = 5;
var $mdgriffith$elm_ui$Internal$Style$Below = 1;
var $mdgriffith$elm_ui$Internal$Style$OnLeft = 3;
var $mdgriffith$elm_ui$Internal$Style$OnRight = 2;
var $mdgriffith$elm_ui$Internal$Style$Within = 4;
var $mdgriffith$elm_ui$Internal$Style$locations = function () {
	var loc = 0;
	var _v0 = function () {
		switch (loc) {
			case 0:
				return 0;
			case 1:
				return 0;
			case 2:
				return 0;
			case 3:
				return 0;
			case 4:
				return 0;
			default:
				return 0;
		}
	}();
	return _List_fromArray(
		[0, 1, 2, 3, 4, 5]);
}();
var $mdgriffith$elm_ui$Internal$Style$baseSheet = _List_fromArray(
	[
		A2(
		$mdgriffith$elm_ui$Internal$Style$Class,
		'html,body',
		_List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', '100%'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'padding', '0'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin', '0')
			])),
		A2(
		$mdgriffith$elm_ui$Internal$Style$Class,
		_Utils_ap(
			$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fV),
			_Utils_ap(
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hy),
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.gF))),
		_List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'block'),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.cQ),
				_List_fromArray(
					[
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						'img',
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'max-height', '100%'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'object-fit', 'cover')
							]))
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.dX),
				_List_fromArray(
					[
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						'img',
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'max-width', '100%'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'object-fit', 'cover')
							]))
					]))
			])),
		A2(
		$mdgriffith$elm_ui$Internal$Style$Class,
		$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fV) + ':focus',
		_List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'outline', 'none')
			])),
		A2(
		$mdgriffith$elm_ui$Internal$Style$Class,
		$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hl),
		_List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', 'auto'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'min-height', '100%'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'z-index', '0'),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				_Utils_ap(
					$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fV),
					$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.cQ)),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', '100%'),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.cQ),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', '100%')
							]))
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Child,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.gH),
				_List_fromArray(
					[
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.bd),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'position', 'fixed'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'z-index', '20')
							]))
					]))
			])),
		A2(
		$mdgriffith$elm_ui$Internal$Style$Class,
		$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.bd),
		_List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'position', 'relative'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'border', 'none'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'flex'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-direction', 'row'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-basis', 'auto'),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hy),
				$mdgriffith$elm_ui$Internal$Style$elDescription),
				$mdgriffith$elm_ui$Internal$Style$Batch(
				function (fn) {
					return A2($elm$core$List$map, fn, $mdgriffith$elm_ui$Internal$Style$locations);
				}(
					function (loc) {
						switch (loc) {
							case 0:
								return A2(
									$mdgriffith$elm_ui$Internal$Style$Descriptor,
									$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fJ),
									_List_fromArray(
										[
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'position', 'absolute'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'bottom', '100%'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'left', '0'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'z-index', '20'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin', '0 !important'),
											A2(
											$mdgriffith$elm_ui$Internal$Style$Child,
											$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.cQ),
											_List_fromArray(
												[
													A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', 'auto')
												])),
											A2(
											$mdgriffith$elm_ui$Internal$Style$Child,
											$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.dX),
											_List_fromArray(
												[
													A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%')
												])),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'none'),
											A2(
											$mdgriffith$elm_ui$Internal$Style$Child,
											'*',
											_List_fromArray(
												[
													A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'auto')
												]))
										]));
							case 1:
								return A2(
									$mdgriffith$elm_ui$Internal$Style$Descriptor,
									$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.f0),
									_List_fromArray(
										[
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'position', 'absolute'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'bottom', '0'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'left', '0'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', '0'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'z-index', '20'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin', '0 !important'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'none'),
											A2(
											$mdgriffith$elm_ui$Internal$Style$Child,
											'*',
											_List_fromArray(
												[
													A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'auto')
												])),
											A2(
											$mdgriffith$elm_ui$Internal$Style$Child,
											$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.cQ),
											_List_fromArray(
												[
													A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', 'auto')
												]))
										]));
							case 2:
								return A2(
									$mdgriffith$elm_ui$Internal$Style$Descriptor,
									$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.g4),
									_List_fromArray(
										[
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'position', 'absolute'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'left', '100%'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'top', '0'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', '100%'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin', '0 !important'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'z-index', '20'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'none'),
											A2(
											$mdgriffith$elm_ui$Internal$Style$Child,
											'*',
											_List_fromArray(
												[
													A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'auto')
												]))
										]));
							case 3:
								return A2(
									$mdgriffith$elm_ui$Internal$Style$Descriptor,
									$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.g3),
									_List_fromArray(
										[
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'position', 'absolute'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'right', '100%'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'top', '0'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', '100%'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin', '0 !important'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'z-index', '20'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'none'),
											A2(
											$mdgriffith$elm_ui$Internal$Style$Child,
											'*',
											_List_fromArray(
												[
													A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'auto')
												]))
										]));
							case 4:
								return A2(
									$mdgriffith$elm_ui$Internal$Style$Descriptor,
									$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.gH),
									_List_fromArray(
										[
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'position', 'absolute'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', '100%'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'left', '0'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'top', '0'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin', '0 !important'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'none'),
											A2(
											$mdgriffith$elm_ui$Internal$Style$Child,
											'*',
											_List_fromArray(
												[
													A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'auto')
												]))
										]));
							default:
								return A2(
									$mdgriffith$elm_ui$Internal$Style$Descriptor,
									$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.f$),
									_List_fromArray(
										[
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'position', 'absolute'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', '100%'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'left', '0'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'top', '0'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin', '0 !important'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'z-index', '0'),
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'none'),
											A2(
											$mdgriffith$elm_ui$Internal$Style$Child,
											'*',
											_List_fromArray(
												[
													A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'auto')
												]))
										]));
						}
					}))
			])),
		A2(
		$mdgriffith$elm_ui$Internal$Style$Class,
		$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fV),
		_List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'position', 'relative'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'border', 'none'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-shrink', '0'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'flex'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-direction', 'row'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-basis', 'auto'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'resize', 'none'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-feature-settings', 'inherit'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'box-sizing', 'border-box'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin', '0'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'padding', '0'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'border-width', '0'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'border-style', 'solid'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-size', 'inherit'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'color', 'inherit'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-family', 'inherit'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'line-height', '1'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-weight', 'inherit'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-decoration', 'none'),
				A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-style', 'inherit'),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.dY),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-wrap', 'wrap')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.eV),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, '-moz-user-select', 'none'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, '-webkit-user-select', 'none'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, '-ms-user-select', 'none'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'user-select', 'none')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.gi),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'cursor', 'pointer')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.gj),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'cursor', 'text')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hb),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'none !important')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.b0),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'auto !important')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.a1),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'opacity', '0')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.aV),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'opacity', '1')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot(
					_Utils_ap($mdgriffith$elm_ui$Internal$Style$classes.gD, $mdgriffith$elm_ui$Internal$Style$classes.a1)) + ':hover',
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'opacity', '0')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot(
					_Utils_ap($mdgriffith$elm_ui$Internal$Style$classes.gD, $mdgriffith$elm_ui$Internal$Style$classes.aV)) + ':hover',
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'opacity', '1')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot(
					_Utils_ap($mdgriffith$elm_ui$Internal$Style$classes.gx, $mdgriffith$elm_ui$Internal$Style$classes.a1)) + ':focus',
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'opacity', '0')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot(
					_Utils_ap($mdgriffith$elm_ui$Internal$Style$classes.gx, $mdgriffith$elm_ui$Internal$Style$classes.aV)) + ':focus',
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'opacity', '1')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot(
					_Utils_ap($mdgriffith$elm_ui$Internal$Style$classes.ct, $mdgriffith$elm_ui$Internal$Style$classes.a1)) + ':active',
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'opacity', '0')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot(
					_Utils_ap($mdgriffith$elm_ui$Internal$Style$classes.ct, $mdgriffith$elm_ui$Internal$Style$classes.aV)) + ':active',
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'opacity', '1')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.V),
				_List_fromArray(
					[
						A2(
						$mdgriffith$elm_ui$Internal$Style$Prop,
						'transition',
						A2(
							$elm$core$String$join,
							', ',
							A2(
								$elm$core$List$map,
								function (x) {
									return x + ' 160ms';
								},
								_List_fromArray(
									['transform', 'opacity', 'filter', 'background-color', 'color', 'font-size']))))
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hr),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'overflow', 'auto'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-shrink', '1')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hs),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'overflow-x', 'auto'),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fh),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-shrink', '1')
							]))
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.ht),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'overflow-y', 'auto'),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.av),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-shrink', '1')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hy),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-shrink', '1')
							]))
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.gb),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'overflow', 'hidden')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.gc),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'overflow-x', 'hidden')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.gd),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'overflow-y', 'hidden')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.dW),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', 'auto')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.bZ),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'border-width', '0')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.f3),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'border-style', 'dashed')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.f4),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'border-style', 'dotted')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.f5),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'border-style', 'solid')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hN),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'white-space', 'pre'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'inline-block')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.gP),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'line-height', '1.05'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'background', 'transparent'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-align', 'inherit')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hy),
				$mdgriffith$elm_ui$Internal$Style$elDescription),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fh),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'flex'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-direction', 'row'),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fV),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-basis', '0%'),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Descriptor,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fE),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-basis', 'auto')
									])),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Descriptor,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.eM),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-basis', 'auto')
									]))
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.cQ),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'stretch !important')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.ew),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'stretch !important')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.dX),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '100000')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.b3),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '0'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-basis', 'auto'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'stretch')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						'u:first-of-type.' + $mdgriffith$elm_ui$Internal$Style$classes.fR,
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '1')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						's:first-of-type.' + $mdgriffith$elm_ui$Internal$Style$classes.fP,
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '1'),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Child,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fM),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-left', 'auto !important')
									]))
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						's:last-of-type.' + $mdgriffith$elm_ui$Internal$Style$classes.fP,
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '1'),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Child,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fM),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-right', 'auto !important')
									]))
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						's:only-of-type.' + $mdgriffith$elm_ui$Internal$Style$classes.fP,
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '1'),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Child,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fN),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-top', 'auto !important'),
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-bottom', 'auto !important')
									]))
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						's:last-of-type.' + ($mdgriffith$elm_ui$Internal$Style$classes.fP + ' ~ u'),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '0')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						'u:first-of-type.' + ($mdgriffith$elm_ui$Internal$Style$classes.fR + (' ~ s.' + $mdgriffith$elm_ui$Internal$Style$classes.fP)),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '0')
							])),
						$mdgriffith$elm_ui$Internal$Style$describeAlignment(
						function (alignment) {
							switch (alignment) {
								case 0:
									return _Utils_Tuple2(
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'flex-start')
											]),
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'flex-start')
											]));
								case 1:
									return _Utils_Tuple2(
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'flex-end')
											]),
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'flex-end')
											]));
								case 2:
									return _Utils_Tuple2(
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'flex-end')
											]),
										_List_Nil);
								case 3:
									return _Utils_Tuple2(
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'flex-start')
											]),
										_List_Nil);
								case 4:
									return _Utils_Tuple2(
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'center')
											]),
										_List_Nil);
								default:
									return _Utils_Tuple2(
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'center')
											]),
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'center')
											]));
							}
						}),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hA),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'space-between')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.cb),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'baseline')
							]))
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.av),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'flex'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-direction', 'column'),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fV),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-basis', '0px'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'min-height', 'min-content'),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Descriptor,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.ev),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-basis', 'auto')
									]))
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.cQ),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '100000')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.dX),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fF),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.dW),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'flex-start')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						'u:first-of-type.' + $mdgriffith$elm_ui$Internal$Style$classes.fO,
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '1')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						's:first-of-type.' + $mdgriffith$elm_ui$Internal$Style$classes.fQ,
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '1'),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Child,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fN),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-top', 'auto !important'),
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-bottom', '0 !important')
									]))
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						's:last-of-type.' + $mdgriffith$elm_ui$Internal$Style$classes.fQ,
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '1'),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Child,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fN),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-bottom', 'auto !important'),
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-top', '0 !important')
									]))
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						's:only-of-type.' + $mdgriffith$elm_ui$Internal$Style$classes.fQ,
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '1'),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Child,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fN),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-top', 'auto !important'),
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-bottom', 'auto !important')
									]))
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						's:last-of-type.' + ($mdgriffith$elm_ui$Internal$Style$classes.fQ + ' ~ u'),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '0')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						'u:first-of-type.' + ($mdgriffith$elm_ui$Internal$Style$classes.fO + (' ~ s.' + $mdgriffith$elm_ui$Internal$Style$classes.fQ)),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '0')
							])),
						$mdgriffith$elm_ui$Internal$Style$describeAlignment(
						function (alignment) {
							switch (alignment) {
								case 0:
									return _Utils_Tuple2(
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'flex-start')
											]),
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-bottom', 'auto')
											]));
								case 1:
									return _Utils_Tuple2(
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'flex-end')
											]),
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin-top', 'auto')
											]));
								case 2:
									return _Utils_Tuple2(
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'flex-end')
											]),
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'flex-end')
											]));
								case 3:
									return _Utils_Tuple2(
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'flex-start')
											]),
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'flex-start')
											]));
								case 4:
									return _Utils_Tuple2(
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'center')
											]),
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'center')
											]));
								default:
									return _Utils_Tuple2(
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'center')
											]),
										_List_Nil);
							}
						}),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.b3),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-grow', '0'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-basis', 'auto'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-self', 'stretch !important')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hA),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'space-between')
							]))
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.gA),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', '-ms-grid'),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						'.gp',
						_List_fromArray(
							[
								A2(
								$mdgriffith$elm_ui$Internal$Style$Child,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fV),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%')
									]))
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Supports,
						_Utils_Tuple2('display', 'grid'),
						_List_fromArray(
							[
								_Utils_Tuple2('display', 'grid')
							])),
						$mdgriffith$elm_ui$Internal$Style$gridAlignments(
						function (alignment) {
							switch (alignment) {
								case 0:
									return _List_fromArray(
										[
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'flex-start')
										]);
								case 1:
									return _List_fromArray(
										[
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'flex-end')
										]);
								case 2:
									return _List_fromArray(
										[
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'flex-end')
										]);
								case 3:
									return _List_fromArray(
										[
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'flex-start')
										]);
								case 4:
									return _List_fromArray(
										[
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'align-items', 'center')
										]);
								default:
									return _List_fromArray(
										[
											A2($mdgriffith$elm_ui$Internal$Style$Prop, 'justify-content', 'center')
										]);
							}
						})
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.e0),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'block'),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fV + ':first-child'),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin', '0 !important')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot(
							$mdgriffith$elm_ui$Internal$Style$classes.fV + ($mdgriffith$elm_ui$Internal$Style$selfName(3) + (':first-child + .' + $mdgriffith$elm_ui$Internal$Style$classes.fV))),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin', '0 !important')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot(
							$mdgriffith$elm_ui$Internal$Style$classes.fV + ($mdgriffith$elm_ui$Internal$Style$selfName(2) + (':first-child + .' + $mdgriffith$elm_ui$Internal$Style$classes.fV))),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'margin', '0 !important')
							])),
						$mdgriffith$elm_ui$Internal$Style$describeAlignment(
						function (alignment) {
							switch (alignment) {
								case 0:
									return _Utils_Tuple2(_List_Nil, _List_Nil);
								case 1:
									return _Utils_Tuple2(_List_Nil, _List_Nil);
								case 2:
									return _Utils_Tuple2(
										_List_Nil,
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'float', 'right'),
												A2(
												$mdgriffith$elm_ui$Internal$Style$Descriptor,
												'::after',
												_List_fromArray(
													[
														A2($mdgriffith$elm_ui$Internal$Style$Prop, 'content', '\"\"'),
														A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'table'),
														A2($mdgriffith$elm_ui$Internal$Style$Prop, 'clear', 'both')
													]))
											]));
								case 3:
									return _Utils_Tuple2(
										_List_Nil,
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'float', 'left'),
												A2(
												$mdgriffith$elm_ui$Internal$Style$Descriptor,
												'::after',
												_List_fromArray(
													[
														A2($mdgriffith$elm_ui$Internal$Style$Prop, 'content', '\"\"'),
														A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'table'),
														A2($mdgriffith$elm_ui$Internal$Style$Prop, 'clear', 'both')
													]))
											]));
								case 4:
									return _Utils_Tuple2(_List_Nil, _List_Nil);
								default:
									return _Utils_Tuple2(_List_Nil, _List_Nil);
							}
						})
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.gL),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'white-space', 'pre-wrap !important'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', '100%'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'background-color', 'transparent')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.gO),
				_List_fromArray(
					[
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hy),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'flex-basis', 'auto')
							]))
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.gN),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'white-space', 'pre-wrap !important'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'cursor', 'text'),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.gM),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'white-space', 'pre-wrap !important'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'color', 'transparent')
							]))
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.e1),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'block'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'white-space', 'normal'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'overflow-wrap', 'break-word'),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Descriptor,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.cN),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'z-index', '0'),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Child,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.f$),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'z-index', '-1')
									]))
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$AllChildren,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hN),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'inline'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'white-space', 'normal')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$AllChildren,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.e1),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'inline'),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Descriptor,
								'::after',
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'content', 'none')
									])),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Descriptor,
								'::before',
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'content', 'none')
									]))
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$AllChildren,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hy),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'inline'),
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'white-space', 'normal'),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Descriptor,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fE),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'inline-block')
									])),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Descriptor,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.gH),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'flex')
									])),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Descriptor,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.f$),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'flex')
									])),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Descriptor,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fJ),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'flex')
									])),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Descriptor,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.f0),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'flex')
									])),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Descriptor,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.g4),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'flex')
									])),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Descriptor,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.g3),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'flex')
									])),
								A2(
								$mdgriffith$elm_ui$Internal$Style$Child,
								$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hN),
								_List_fromArray(
									[
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'inline'),
										A2($mdgriffith$elm_ui$Internal$Style$Prop, 'white-space', 'normal')
									]))
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fh),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'inline')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.av),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'inline-flex')
							])),
						A2(
						$mdgriffith$elm_ui$Internal$Style$Child,
						$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.gA),
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'inline-grid')
							])),
						$mdgriffith$elm_ui$Internal$Style$describeAlignment(
						function (alignment) {
							switch (alignment) {
								case 0:
									return _Utils_Tuple2(_List_Nil, _List_Nil);
								case 1:
									return _Utils_Tuple2(_List_Nil, _List_Nil);
								case 2:
									return _Utils_Tuple2(
										_List_Nil,
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'float', 'right')
											]));
								case 3:
									return _Utils_Tuple2(
										_List_Nil,
										_List_fromArray(
											[
												A2($mdgriffith$elm_ui$Internal$Style$Prop, 'float', 'left')
											]));
								case 4:
									return _Utils_Tuple2(_List_Nil, _List_Nil);
								default:
									return _Utils_Tuple2(_List_Nil, _List_Nil);
							}
						})
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				'.hidden',
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'display', 'none')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hZ),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-weight', '100')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hQ),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-weight', '200')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hU),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-weight', '300')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hW),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-weight', '400')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hV),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-weight', '500')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hY),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-weight', '600')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.f1),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-weight', '700')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hP),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-weight', '800')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hR),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-weight', '900')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.gR),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-style', 'italic')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hI),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-decoration', 'line-through')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.h7),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-decoration', 'underline'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-decoration-skip-ink', 'auto'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-decoration-skip', 'ink')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				_Utils_ap(
					$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.h7),
					$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hI)),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-decoration', 'line-through underline'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-decoration-skip-ink', 'auto'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-decoration-skip', 'ink')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.h_),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-style', 'normal')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hS),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-align', 'justify')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.cn),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-align', 'justify-all')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hO),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-align', 'center')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hX),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-align', 'right')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				$mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.hT),
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'text-align', 'left')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Descriptor,
				'.modal',
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'position', 'fixed'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'left', '0'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'top', '0'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'width', '100%'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'height', '100%'),
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'pointer-events', 'none')
					]))
			]))
	]);
var $mdgriffith$elm_ui$Internal$Style$fontVariant = function (_var) {
	return _List_fromArray(
		[
			A2(
			$mdgriffith$elm_ui$Internal$Style$Class,
			'.v-' + _var,
			_List_fromArray(
				[
					A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-feature-settings', '\"' + (_var + '\"'))
				])),
			A2(
			$mdgriffith$elm_ui$Internal$Style$Class,
			'.v-' + (_var + '-off'),
			_List_fromArray(
				[
					A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-feature-settings', '\"' + (_var + '\" 0'))
				]))
		]);
};
var $mdgriffith$elm_ui$Internal$Style$commonValues = $elm$core$List$concat(
	_List_fromArray(
		[
			A2(
			$elm$core$List$map,
			function (x) {
				return A2(
					$mdgriffith$elm_ui$Internal$Style$Class,
					'.border-' + $elm$core$String$fromInt(x),
					_List_fromArray(
						[
							A2(
							$mdgriffith$elm_ui$Internal$Style$Prop,
							'border-width',
							$elm$core$String$fromInt(x) + 'px')
						]));
			},
			A2($elm$core$List$range, 0, 6)),
			A2(
			$elm$core$List$map,
			function (i) {
				return A2(
					$mdgriffith$elm_ui$Internal$Style$Class,
					'.font-size-' + $elm$core$String$fromInt(i),
					_List_fromArray(
						[
							A2(
							$mdgriffith$elm_ui$Internal$Style$Prop,
							'font-size',
							$elm$core$String$fromInt(i) + 'px')
						]));
			},
			A2($elm$core$List$range, 8, 32)),
			A2(
			$elm$core$List$map,
			function (i) {
				return A2(
					$mdgriffith$elm_ui$Internal$Style$Class,
					'.p-' + $elm$core$String$fromInt(i),
					_List_fromArray(
						[
							A2(
							$mdgriffith$elm_ui$Internal$Style$Prop,
							'padding',
							$elm$core$String$fromInt(i) + 'px')
						]));
			},
			A2($elm$core$List$range, 0, 24)),
			_List_fromArray(
			[
				A2(
				$mdgriffith$elm_ui$Internal$Style$Class,
				'.v-smcp',
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-variant', 'small-caps')
					])),
				A2(
				$mdgriffith$elm_ui$Internal$Style$Class,
				'.v-smcp-off',
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Internal$Style$Prop, 'font-variant', 'normal')
					]))
			]),
			$mdgriffith$elm_ui$Internal$Style$fontVariant('zero'),
			$mdgriffith$elm_ui$Internal$Style$fontVariant('onum'),
			$mdgriffith$elm_ui$Internal$Style$fontVariant('liga'),
			$mdgriffith$elm_ui$Internal$Style$fontVariant('dlig'),
			$mdgriffith$elm_ui$Internal$Style$fontVariant('ordn'),
			$mdgriffith$elm_ui$Internal$Style$fontVariant('tnum'),
			$mdgriffith$elm_ui$Internal$Style$fontVariant('afrc'),
			$mdgriffith$elm_ui$Internal$Style$fontVariant('frac')
		]));
var $mdgriffith$elm_ui$Internal$Style$explainer = '\n.explain {\n    border: 6px solid rgb(174, 121, 15) !important;\n}\n.explain > .' + ($mdgriffith$elm_ui$Internal$Style$classes.fV + (' {\n    border: 4px dashed rgb(0, 151, 167) !important;\n}\n\n.ctr {\n    border: none !important;\n}\n.explain > .ctr > .' + ($mdgriffith$elm_ui$Internal$Style$classes.fV + ' {\n    border: 4px dashed rgb(0, 151, 167) !important;\n}\n\n')));
var $mdgriffith$elm_ui$Internal$Style$inputTextReset = '\ninput[type="search"],\ninput[type="search"]::-webkit-search-decoration,\ninput[type="search"]::-webkit-search-cancel-button,\ninput[type="search"]::-webkit-search-results-button,\ninput[type="search"]::-webkit-search-results-decoration {\n  -webkit-appearance:none;\n}\n';
var $mdgriffith$elm_ui$Internal$Style$sliderReset = '\ninput[type=range] {\n  -webkit-appearance: none; \n  background: transparent;\n  position:absolute;\n  left:0;\n  top:0;\n  z-index:10;\n  width: 100%;\n  outline: dashed 1px;\n  height: 100%;\n  opacity: 0;\n}\n';
var $mdgriffith$elm_ui$Internal$Style$thumbReset = '\ninput[type=range]::-webkit-slider-thumb {\n    -webkit-appearance: none;\n    opacity: 0.5;\n    width: 80px;\n    height: 80px;\n    background-color: black;\n    border:none;\n    border-radius: 5px;\n}\ninput[type=range]::-moz-range-thumb {\n    opacity: 0.5;\n    width: 80px;\n    height: 80px;\n    background-color: black;\n    border:none;\n    border-radius: 5px;\n}\ninput[type=range]::-ms-thumb {\n    opacity: 0.5;\n    width: 80px;\n    height: 80px;\n    background-color: black;\n    border:none;\n    border-radius: 5px;\n}\ninput[type=range][orient=vertical]{\n    writing-mode: bt-lr; /* IE */\n    -webkit-appearance: slider-vertical;  /* WebKit */\n}\n';
var $mdgriffith$elm_ui$Internal$Style$trackReset = '\ninput[type=range]::-moz-range-track {\n    background: transparent;\n    cursor: pointer;\n}\ninput[type=range]::-ms-track {\n    background: transparent;\n    cursor: pointer;\n}\ninput[type=range]::-webkit-slider-runnable-track {\n    background: transparent;\n    cursor: pointer;\n}\n';
var $mdgriffith$elm_ui$Internal$Style$overrides = '@media screen and (-ms-high-contrast: active), (-ms-high-contrast: none) {' + ($mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fV) + ($mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fh) + (' > ' + ($mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fV) + (' { flex-basis: auto !important; } ' + ($mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fV) + ($mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fh) + (' > ' + ($mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fV) + ($mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.b3) + (' { flex-basis: auto !important; }}' + ($mdgriffith$elm_ui$Internal$Style$inputTextReset + ($mdgriffith$elm_ui$Internal$Style$sliderReset + ($mdgriffith$elm_ui$Internal$Style$trackReset + ($mdgriffith$elm_ui$Internal$Style$thumbReset + $mdgriffith$elm_ui$Internal$Style$explainer)))))))))))))));
var $mdgriffith$elm_ui$Internal$Style$Intermediate = $elm$core$Basics$identity;
var $mdgriffith$elm_ui$Internal$Style$emptyIntermediate = F2(
	function (selector, closing) {
		return {b1: closing, w: _List_Nil, aE: _List_Nil, ah: selector};
	});
var $mdgriffith$elm_ui$Internal$Style$renderRules = F2(
	function (_v0, rulesToRender) {
		var parent = _v0;
		var generateIntermediates = F2(
			function (rule, rendered) {
				switch (rule.$) {
					case 0:
						var name = rule.a;
						var val = rule.b;
						return _Utils_update(
							rendered,
							{
								aE: A2(
									$elm$core$List$cons,
									_Utils_Tuple2(name, val),
									rendered.aE)
							});
					case 3:
						var _v2 = rule.a;
						var prop = _v2.a;
						var value = _v2.b;
						var props = rule.b;
						return _Utils_update(
							rendered,
							{
								w: A2(
									$elm$core$List$cons,
									{b1: '\n}', w: _List_Nil, aE: props, ah: '@supports (' + (prop + (':' + (value + (') {' + parent.ah))))},
									rendered.w)
							});
					case 5:
						var selector = rule.a;
						var adjRules = rule.b;
						return _Utils_update(
							rendered,
							{
								w: A2(
									$elm$core$List$cons,
									A2(
										$mdgriffith$elm_ui$Internal$Style$renderRules,
										A2($mdgriffith$elm_ui$Internal$Style$emptyIntermediate, parent.ah + (' + ' + selector), ''),
										adjRules),
									rendered.w)
							});
					case 1:
						var child = rule.a;
						var childRules = rule.b;
						return _Utils_update(
							rendered,
							{
								w: A2(
									$elm$core$List$cons,
									A2(
										$mdgriffith$elm_ui$Internal$Style$renderRules,
										A2($mdgriffith$elm_ui$Internal$Style$emptyIntermediate, parent.ah + (' > ' + child), ''),
										childRules),
									rendered.w)
							});
					case 2:
						var child = rule.a;
						var childRules = rule.b;
						return _Utils_update(
							rendered,
							{
								w: A2(
									$elm$core$List$cons,
									A2(
										$mdgriffith$elm_ui$Internal$Style$renderRules,
										A2($mdgriffith$elm_ui$Internal$Style$emptyIntermediate, parent.ah + (' ' + child), ''),
										childRules),
									rendered.w)
							});
					case 4:
						var descriptor = rule.a;
						var descriptorRules = rule.b;
						return _Utils_update(
							rendered,
							{
								w: A2(
									$elm$core$List$cons,
									A2(
										$mdgriffith$elm_ui$Internal$Style$renderRules,
										A2(
											$mdgriffith$elm_ui$Internal$Style$emptyIntermediate,
											_Utils_ap(parent.ah, descriptor),
											''),
										descriptorRules),
									rendered.w)
							});
					default:
						var batched = rule.a;
						return _Utils_update(
							rendered,
							{
								w: A2(
									$elm$core$List$cons,
									A2(
										$mdgriffith$elm_ui$Internal$Style$renderRules,
										A2($mdgriffith$elm_ui$Internal$Style$emptyIntermediate, parent.ah, ''),
										batched),
									rendered.w)
							});
				}
			});
		return A3($elm$core$List$foldr, generateIntermediates, parent, rulesToRender);
	});
var $mdgriffith$elm_ui$Internal$Style$renderCompact = function (styleClasses) {
	var renderValues = function (values) {
		return $elm$core$String$concat(
			A2(
				$elm$core$List$map,
				function (_v3) {
					var x = _v3.a;
					var y = _v3.b;
					return x + (':' + (y + ';'));
				},
				values));
	};
	var renderClass = function (rule) {
		var _v2 = rule.aE;
		if (!_v2.b) {
			return '';
		} else {
			return rule.ah + ('{' + (renderValues(rule.aE) + (rule.b1 + '}')));
		}
	};
	var renderIntermediate = function (_v0) {
		var rule = _v0;
		return _Utils_ap(
			renderClass(rule),
			$elm$core$String$concat(
				A2($elm$core$List$map, renderIntermediate, rule.w)));
	};
	return $elm$core$String$concat(
		A2(
			$elm$core$List$map,
			renderIntermediate,
			A3(
				$elm$core$List$foldr,
				F2(
					function (_v1, existing) {
						var name = _v1.a;
						var styleRules = _v1.b;
						return A2(
							$elm$core$List$cons,
							A2(
								$mdgriffith$elm_ui$Internal$Style$renderRules,
								A2($mdgriffith$elm_ui$Internal$Style$emptyIntermediate, name, ''),
								styleRules),
							existing);
					}),
				_List_Nil,
				styleClasses)));
};
var $mdgriffith$elm_ui$Internal$Style$rules = _Utils_ap(
	$mdgriffith$elm_ui$Internal$Style$overrides,
	$mdgriffith$elm_ui$Internal$Style$renderCompact(
		_Utils_ap($mdgriffith$elm_ui$Internal$Style$baseSheet, $mdgriffith$elm_ui$Internal$Style$commonValues)));
var $elm$virtual_dom$VirtualDom$text = _VirtualDom_text;
var $mdgriffith$elm_ui$Internal$Model$staticRoot = function (opts) {
	var _v0 = opts.gY;
	switch (_v0) {
		case 0:
			return A3(
				$elm$virtual_dom$VirtualDom$node,
				'div',
				_List_Nil,
				_List_fromArray(
					[
						A3(
						$elm$virtual_dom$VirtualDom$node,
						'style',
						_List_Nil,
						_List_fromArray(
							[
								$elm$virtual_dom$VirtualDom$text($mdgriffith$elm_ui$Internal$Style$rules)
							]))
					]));
		case 1:
			return $elm$virtual_dom$VirtualDom$text('');
		default:
			return A3(
				$elm$virtual_dom$VirtualDom$node,
				'elm-ui-static-rules',
				_List_fromArray(
					[
						A2(
						$elm$virtual_dom$VirtualDom$property,
						'rules',
						$elm$json$Json$Encode$string($mdgriffith$elm_ui$Internal$Style$rules))
					]),
				_List_Nil);
	}
};
var $mdgriffith$elm_ui$Internal$Model$fontName = function (font) {
	switch (font.$) {
		case 0:
			return 'serif';
		case 1:
			return 'sans-serif';
		case 2:
			return 'monospace';
		case 3:
			var name = font.a;
			return '\"' + (name + '\"');
		case 4:
			var name = font.a;
			var url = font.b;
			return '\"' + (name + '\"');
		default:
			var name = font.a.gZ;
			return '\"' + (name + '\"');
	}
};
var $mdgriffith$elm_ui$Internal$Model$isSmallCaps = function (_var) {
	switch (_var.$) {
		case 0:
			var name = _var.a;
			return name === 'smcp';
		case 1:
			var name = _var.a;
			return false;
		default:
			var name = _var.a;
			var index = _var.b;
			return (name === 'smcp') && (index === 1);
	}
};
var $mdgriffith$elm_ui$Internal$Model$hasSmallCaps = function (typeface) {
	if (typeface.$ === 5) {
		var font = typeface.a;
		return A2($elm$core$List$any, $mdgriffith$elm_ui$Internal$Model$isSmallCaps, font.fz);
	} else {
		return false;
	}
};
var $mdgriffith$elm_ui$Internal$Model$renderProps = F3(
	function (force, _v0, existing) {
		var key = _v0.a;
		var val = _v0.b;
		return force ? (existing + ('\n  ' + (key + (': ' + (val + ' !important;'))))) : (existing + ('\n  ' + (key + (': ' + (val + ';')))));
	});
var $mdgriffith$elm_ui$Internal$Model$renderStyle = F4(
	function (options, maybePseudo, selector, props) {
		if (maybePseudo.$ === 1) {
			return _List_fromArray(
				[
					selector + ('{' + (A3(
					$elm$core$List$foldl,
					$mdgriffith$elm_ui$Internal$Model$renderProps(false),
					'',
					props) + '\n}'))
				]);
		} else {
			var pseudo = maybePseudo.a;
			switch (pseudo) {
				case 1:
					var _v2 = options.gD;
					switch (_v2) {
						case 0:
							return _List_Nil;
						case 2:
							return _List_fromArray(
								[
									selector + ('-hv {' + (A3(
									$elm$core$List$foldl,
									$mdgriffith$elm_ui$Internal$Model$renderProps(true),
									'',
									props) + '\n}'))
								]);
						default:
							return _List_fromArray(
								[
									selector + ('-hv:hover {' + (A3(
									$elm$core$List$foldl,
									$mdgriffith$elm_ui$Internal$Model$renderProps(false),
									'',
									props) + '\n}'))
								]);
					}
				case 0:
					var renderedProps = A3(
						$elm$core$List$foldl,
						$mdgriffith$elm_ui$Internal$Model$renderProps(false),
						'',
						props);
					return _List_fromArray(
						[
							selector + ('-fs:focus {' + (renderedProps + '\n}')),
							('.' + ($mdgriffith$elm_ui$Internal$Style$classes.fV + (':focus ' + (selector + '-fs  {')))) + (renderedProps + '\n}'),
							(selector + '-fs:focus-within {') + (renderedProps + '\n}'),
							('.ui-slide-bar:focus + ' + ($mdgriffith$elm_ui$Internal$Style$dot($mdgriffith$elm_ui$Internal$Style$classes.fV) + (' .focusable-thumb' + (selector + '-fs {')))) + (renderedProps + '\n}')
						]);
				default:
					return _List_fromArray(
						[
							selector + ('-act:active {' + (A3(
							$elm$core$List$foldl,
							$mdgriffith$elm_ui$Internal$Model$renderProps(false),
							'',
							props) + '\n}'))
						]);
			}
		}
	});
var $mdgriffith$elm_ui$Internal$Model$renderVariant = function (_var) {
	switch (_var.$) {
		case 0:
			var name = _var.a;
			return '\"' + (name + '\"');
		case 1:
			var name = _var.a;
			return '\"' + (name + '\" 0');
		default:
			var name = _var.a;
			var index = _var.b;
			return '\"' + (name + ('\" ' + $elm$core$String$fromInt(index)));
	}
};
var $mdgriffith$elm_ui$Internal$Model$renderVariants = function (typeface) {
	if (typeface.$ === 5) {
		var font = typeface.a;
		return $elm$core$Maybe$Just(
			A2(
				$elm$core$String$join,
				', ',
				A2($elm$core$List$map, $mdgriffith$elm_ui$Internal$Model$renderVariant, font.fz)));
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $mdgriffith$elm_ui$Internal$Model$transformValue = function (transform) {
	switch (transform.$) {
		case 0:
			return $elm$core$Maybe$Nothing;
		case 1:
			var _v1 = transform.a;
			var x = _v1.a;
			var y = _v1.b;
			var z = _v1.c;
			return $elm$core$Maybe$Just(
				'translate3d(' + ($elm$core$String$fromFloat(x) + ('px, ' + ($elm$core$String$fromFloat(y) + ('px, ' + ($elm$core$String$fromFloat(z) + 'px)'))))));
		default:
			var _v2 = transform.a;
			var tx = _v2.a;
			var ty = _v2.b;
			var tz = _v2.c;
			var _v3 = transform.b;
			var sx = _v3.a;
			var sy = _v3.b;
			var sz = _v3.c;
			var _v4 = transform.c;
			var ox = _v4.a;
			var oy = _v4.b;
			var oz = _v4.c;
			var angle = transform.d;
			var translate = 'translate3d(' + ($elm$core$String$fromFloat(tx) + ('px, ' + ($elm$core$String$fromFloat(ty) + ('px, ' + ($elm$core$String$fromFloat(tz) + 'px)')))));
			var scale = 'scale3d(' + ($elm$core$String$fromFloat(sx) + (', ' + ($elm$core$String$fromFloat(sy) + (', ' + ($elm$core$String$fromFloat(sz) + ')')))));
			var rotate = 'rotate3d(' + ($elm$core$String$fromFloat(ox) + (', ' + ($elm$core$String$fromFloat(oy) + (', ' + ($elm$core$String$fromFloat(oz) + (', ' + ($elm$core$String$fromFloat(angle) + 'rad)')))))));
			return $elm$core$Maybe$Just(translate + (' ' + (scale + (' ' + rotate))));
	}
};
var $mdgriffith$elm_ui$Internal$Model$renderStyleRule = F3(
	function (options, rule, maybePseudo) {
		switch (rule.$) {
			case 0:
				var selector = rule.a;
				var props = rule.b;
				return A4($mdgriffith$elm_ui$Internal$Model$renderStyle, options, maybePseudo, selector, props);
			case 13:
				var name = rule.a;
				var prop = rule.b;
				return A4(
					$mdgriffith$elm_ui$Internal$Model$renderStyle,
					options,
					maybePseudo,
					'.' + name,
					_List_fromArray(
						[
							A2($mdgriffith$elm_ui$Internal$Model$Property, 'box-shadow', prop)
						]));
			case 12:
				var name = rule.a;
				var transparency = rule.b;
				var opacity = A2(
					$elm$core$Basics$max,
					0,
					A2($elm$core$Basics$min, 1, 1 - transparency));
				return A4(
					$mdgriffith$elm_ui$Internal$Model$renderStyle,
					options,
					maybePseudo,
					'.' + name,
					_List_fromArray(
						[
							A2(
							$mdgriffith$elm_ui$Internal$Model$Property,
							'opacity',
							$elm$core$String$fromFloat(opacity))
						]));
			case 2:
				var i = rule.a;
				return A4(
					$mdgriffith$elm_ui$Internal$Model$renderStyle,
					options,
					maybePseudo,
					'.font-size-' + $elm$core$String$fromInt(i),
					_List_fromArray(
						[
							A2(
							$mdgriffith$elm_ui$Internal$Model$Property,
							'font-size',
							$elm$core$String$fromInt(i) + 'px')
						]));
			case 1:
				var name = rule.a;
				var typefaces = rule.b;
				var features = A2(
					$elm$core$String$join,
					', ',
					A2($elm$core$List$filterMap, $mdgriffith$elm_ui$Internal$Model$renderVariants, typefaces));
				var families = _List_fromArray(
					[
						A2(
						$mdgriffith$elm_ui$Internal$Model$Property,
						'font-family',
						A2(
							$elm$core$String$join,
							', ',
							A2($elm$core$List$map, $mdgriffith$elm_ui$Internal$Model$fontName, typefaces))),
						A2($mdgriffith$elm_ui$Internal$Model$Property, 'font-feature-settings', features),
						A2(
						$mdgriffith$elm_ui$Internal$Model$Property,
						'font-variant',
						A2($elm$core$List$any, $mdgriffith$elm_ui$Internal$Model$hasSmallCaps, typefaces) ? 'small-caps' : 'normal')
					]);
				return A4($mdgriffith$elm_ui$Internal$Model$renderStyle, options, maybePseudo, '.' + name, families);
			case 3:
				var _class = rule.a;
				var prop = rule.b;
				var val = rule.c;
				return A4(
					$mdgriffith$elm_ui$Internal$Model$renderStyle,
					options,
					maybePseudo,
					'.' + _class,
					_List_fromArray(
						[
							A2($mdgriffith$elm_ui$Internal$Model$Property, prop, val)
						]));
			case 4:
				var _class = rule.a;
				var prop = rule.b;
				var color = rule.c;
				return A4(
					$mdgriffith$elm_ui$Internal$Model$renderStyle,
					options,
					maybePseudo,
					'.' + _class,
					_List_fromArray(
						[
							A2(
							$mdgriffith$elm_ui$Internal$Model$Property,
							prop,
							$mdgriffith$elm_ui$Internal$Model$formatColor(color))
						]));
			case 5:
				var cls = rule.a;
				var x = rule.b;
				var y = rule.c;
				var yPx = $elm$core$String$fromInt(y) + 'px';
				var xPx = $elm$core$String$fromInt(x) + 'px';
				var single = '.' + $mdgriffith$elm_ui$Internal$Style$classes.hy;
				var row = '.' + $mdgriffith$elm_ui$Internal$Style$classes.fh;
				var wrappedRow = '.' + ($mdgriffith$elm_ui$Internal$Style$classes.dY + row);
				var right = '.' + $mdgriffith$elm_ui$Internal$Style$classes.d8;
				var paragraph = '.' + $mdgriffith$elm_ui$Internal$Style$classes.e1;
				var page = '.' + $mdgriffith$elm_ui$Internal$Style$classes.e0;
				var left = '.' + $mdgriffith$elm_ui$Internal$Style$classes.d7;
				var halfY = $elm$core$String$fromFloat(y / 2) + 'px';
				var halfX = $elm$core$String$fromFloat(x / 2) + 'px';
				var column = '.' + $mdgriffith$elm_ui$Internal$Style$classes.av;
				var _class = '.' + cls;
				var any = '.' + $mdgriffith$elm_ui$Internal$Style$classes.fV;
				return $elm$core$List$concat(
					_List_fromArray(
						[
							A4(
							$mdgriffith$elm_ui$Internal$Model$renderStyle,
							options,
							maybePseudo,
							_class + (row + (' > ' + (any + (' + ' + any)))),
							_List_fromArray(
								[
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'margin-left', xPx)
								])),
							A4(
							$mdgriffith$elm_ui$Internal$Model$renderStyle,
							options,
							maybePseudo,
							_class + (wrappedRow + (' > ' + any)),
							_List_fromArray(
								[
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'margin', halfY + (' ' + halfX))
								])),
							A4(
							$mdgriffith$elm_ui$Internal$Model$renderStyle,
							options,
							maybePseudo,
							_class + (column + (' > ' + (any + (' + ' + any)))),
							_List_fromArray(
								[
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'margin-top', yPx)
								])),
							A4(
							$mdgriffith$elm_ui$Internal$Model$renderStyle,
							options,
							maybePseudo,
							_class + (page + (' > ' + (any + (' + ' + any)))),
							_List_fromArray(
								[
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'margin-top', yPx)
								])),
							A4(
							$mdgriffith$elm_ui$Internal$Model$renderStyle,
							options,
							maybePseudo,
							_class + (page + (' > ' + left)),
							_List_fromArray(
								[
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'margin-right', xPx)
								])),
							A4(
							$mdgriffith$elm_ui$Internal$Model$renderStyle,
							options,
							maybePseudo,
							_class + (page + (' > ' + right)),
							_List_fromArray(
								[
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'margin-left', xPx)
								])),
							A4(
							$mdgriffith$elm_ui$Internal$Model$renderStyle,
							options,
							maybePseudo,
							_Utils_ap(_class, paragraph),
							_List_fromArray(
								[
									A2(
									$mdgriffith$elm_ui$Internal$Model$Property,
									'line-height',
									'calc(1em + ' + ($elm$core$String$fromInt(y) + 'px)'))
								])),
							A4(
							$mdgriffith$elm_ui$Internal$Model$renderStyle,
							options,
							maybePseudo,
							'textarea' + (any + _class),
							_List_fromArray(
								[
									A2(
									$mdgriffith$elm_ui$Internal$Model$Property,
									'line-height',
									'calc(1em + ' + ($elm$core$String$fromInt(y) + 'px)')),
									A2(
									$mdgriffith$elm_ui$Internal$Model$Property,
									'height',
									'calc(100% + ' + ($elm$core$String$fromInt(y) + 'px)'))
								])),
							A4(
							$mdgriffith$elm_ui$Internal$Model$renderStyle,
							options,
							maybePseudo,
							_class + (paragraph + (' > ' + left)),
							_List_fromArray(
								[
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'margin-right', xPx)
								])),
							A4(
							$mdgriffith$elm_ui$Internal$Model$renderStyle,
							options,
							maybePseudo,
							_class + (paragraph + (' > ' + right)),
							_List_fromArray(
								[
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'margin-left', xPx)
								])),
							A4(
							$mdgriffith$elm_ui$Internal$Model$renderStyle,
							options,
							maybePseudo,
							_class + (paragraph + '::after'),
							_List_fromArray(
								[
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'content', '\'\''),
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'display', 'block'),
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'height', '0'),
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'width', '0'),
									A2(
									$mdgriffith$elm_ui$Internal$Model$Property,
									'margin-top',
									$elm$core$String$fromInt((-1) * ((y / 2) | 0)) + 'px')
								])),
							A4(
							$mdgriffith$elm_ui$Internal$Model$renderStyle,
							options,
							maybePseudo,
							_class + (paragraph + '::before'),
							_List_fromArray(
								[
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'content', '\'\''),
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'display', 'block'),
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'height', '0'),
									A2($mdgriffith$elm_ui$Internal$Model$Property, 'width', '0'),
									A2(
									$mdgriffith$elm_ui$Internal$Model$Property,
									'margin-bottom',
									$elm$core$String$fromInt((-1) * ((y / 2) | 0)) + 'px')
								]))
						]));
			case 7:
				var cls = rule.a;
				var top = rule.b;
				var right = rule.c;
				var bottom = rule.d;
				var left = rule.e;
				var _class = '.' + cls;
				return A4(
					$mdgriffith$elm_ui$Internal$Model$renderStyle,
					options,
					maybePseudo,
					_class,
					_List_fromArray(
						[
							A2(
							$mdgriffith$elm_ui$Internal$Model$Property,
							'padding',
							$elm$core$String$fromFloat(top) + ('px ' + ($elm$core$String$fromFloat(right) + ('px ' + ($elm$core$String$fromFloat(bottom) + ('px ' + ($elm$core$String$fromFloat(left) + 'px')))))))
						]));
			case 6:
				var cls = rule.a;
				var top = rule.b;
				var right = rule.c;
				var bottom = rule.d;
				var left = rule.e;
				var _class = '.' + cls;
				return A4(
					$mdgriffith$elm_ui$Internal$Model$renderStyle,
					options,
					maybePseudo,
					_class,
					_List_fromArray(
						[
							A2(
							$mdgriffith$elm_ui$Internal$Model$Property,
							'border-width',
							$elm$core$String$fromInt(top) + ('px ' + ($elm$core$String$fromInt(right) + ('px ' + ($elm$core$String$fromInt(bottom) + ('px ' + ($elm$core$String$fromInt(left) + 'px')))))))
						]));
			case 8:
				var template = rule.a;
				var toGridLengthHelper = F3(
					function (minimum, maximum, x) {
						toGridLengthHelper:
						while (true) {
							switch (x.$) {
								case 0:
									var px = x.a;
									return $elm$core$String$fromInt(px) + 'px';
								case 1:
									var _v2 = _Utils_Tuple2(minimum, maximum);
									if (_v2.a.$ === 1) {
										if (_v2.b.$ === 1) {
											var _v3 = _v2.a;
											var _v4 = _v2.b;
											return 'max-content';
										} else {
											var _v6 = _v2.a;
											var maxSize = _v2.b.a;
											return 'minmax(max-content, ' + ($elm$core$String$fromInt(maxSize) + 'px)');
										}
									} else {
										if (_v2.b.$ === 1) {
											var minSize = _v2.a.a;
											var _v5 = _v2.b;
											return 'minmax(' + ($elm$core$String$fromInt(minSize) + ('px, ' + 'max-content)'));
										} else {
											var minSize = _v2.a.a;
											var maxSize = _v2.b.a;
											return 'minmax(' + ($elm$core$String$fromInt(minSize) + ('px, ' + ($elm$core$String$fromInt(maxSize) + 'px)')));
										}
									}
								case 2:
									var i = x.a;
									var _v7 = _Utils_Tuple2(minimum, maximum);
									if (_v7.a.$ === 1) {
										if (_v7.b.$ === 1) {
											var _v8 = _v7.a;
											var _v9 = _v7.b;
											return $elm$core$String$fromInt(i) + 'fr';
										} else {
											var _v11 = _v7.a;
											var maxSize = _v7.b.a;
											return 'minmax(max-content, ' + ($elm$core$String$fromInt(maxSize) + 'px)');
										}
									} else {
										if (_v7.b.$ === 1) {
											var minSize = _v7.a.a;
											var _v10 = _v7.b;
											return 'minmax(' + ($elm$core$String$fromInt(minSize) + ('px, ' + ($elm$core$String$fromInt(i) + ('fr' + 'fr)'))));
										} else {
											var minSize = _v7.a.a;
											var maxSize = _v7.b.a;
											return 'minmax(' + ($elm$core$String$fromInt(minSize) + ('px, ' + ($elm$core$String$fromInt(maxSize) + 'px)')));
										}
									}
								case 3:
									var m = x.a;
									var len = x.b;
									var $temp$minimum = $elm$core$Maybe$Just(m),
										$temp$maximum = maximum,
										$temp$x = len;
									minimum = $temp$minimum;
									maximum = $temp$maximum;
									x = $temp$x;
									continue toGridLengthHelper;
								default:
									var m = x.a;
									var len = x.b;
									var $temp$minimum = minimum,
										$temp$maximum = $elm$core$Maybe$Just(m),
										$temp$x = len;
									minimum = $temp$minimum;
									maximum = $temp$maximum;
									x = $temp$x;
									continue toGridLengthHelper;
							}
						}
					});
				var toGridLength = function (x) {
					return A3(toGridLengthHelper, $elm$core$Maybe$Nothing, $elm$core$Maybe$Nothing, x);
				};
				var xSpacing = toGridLength(template.hB.a);
				var ySpacing = toGridLength(template.hB.b);
				var rows = function (x) {
					return 'grid-template-rows: ' + (x + ';');
				}(
					A2(
						$elm$core$String$join,
						' ',
						A2($elm$core$List$map, toGridLength, template.hn)));
				var msRows = function (x) {
					return '-ms-grid-rows: ' + (x + ';');
				}(
					A2(
						$elm$core$String$join,
						ySpacing,
						A2($elm$core$List$map, toGridLength, template.b2)));
				var msColumns = function (x) {
					return '-ms-grid-columns: ' + (x + ';');
				}(
					A2(
						$elm$core$String$join,
						ySpacing,
						A2($elm$core$List$map, toGridLength, template.b2)));
				var gapY = 'grid-row-gap:' + (toGridLength(template.hB.b) + ';');
				var gapX = 'grid-column-gap:' + (toGridLength(template.hB.a) + ';');
				var columns = function (x) {
					return 'grid-template-columns: ' + (x + ';');
				}(
					A2(
						$elm$core$String$join,
						' ',
						A2($elm$core$List$map, toGridLength, template.b2)));
				var _class = '.grid-rows-' + (A2(
					$elm$core$String$join,
					'-',
					A2($elm$core$List$map, $mdgriffith$elm_ui$Internal$Model$lengthClassName, template.hn)) + ('-cols-' + (A2(
					$elm$core$String$join,
					'-',
					A2($elm$core$List$map, $mdgriffith$elm_ui$Internal$Model$lengthClassName, template.b2)) + ('-space-x-' + ($mdgriffith$elm_ui$Internal$Model$lengthClassName(template.hB.a) + ('-space-y-' + $mdgriffith$elm_ui$Internal$Model$lengthClassName(template.hB.b)))))));
				var modernGrid = _class + ('{' + (columns + (rows + (gapX + (gapY + '}')))));
				var supports = '@supports (display:grid) {' + (modernGrid + '}');
				var base = _class + ('{' + (msColumns + (msRows + '}')));
				return _List_fromArray(
					[base, supports]);
			case 9:
				var position = rule.a;
				var msPosition = A2(
					$elm$core$String$join,
					' ',
					_List_fromArray(
						[
							'-ms-grid-row: ' + ($elm$core$String$fromInt(position.fh) + ';'),
							'-ms-grid-row-span: ' + ($elm$core$String$fromInt(position.cO) + ';'),
							'-ms-grid-column: ' + ($elm$core$String$fromInt(position.ef) + ';'),
							'-ms-grid-column-span: ' + ($elm$core$String$fromInt(position.aL) + ';')
						]));
				var modernPosition = A2(
					$elm$core$String$join,
					' ',
					_List_fromArray(
						[
							'grid-row: ' + ($elm$core$String$fromInt(position.fh) + (' / ' + ($elm$core$String$fromInt(position.fh + position.cO) + ';'))),
							'grid-column: ' + ($elm$core$String$fromInt(position.ef) + (' / ' + ($elm$core$String$fromInt(position.ef + position.aL) + ';')))
						]));
				var _class = '.grid-pos-' + ($elm$core$String$fromInt(position.fh) + ('-' + ($elm$core$String$fromInt(position.ef) + ('-' + ($elm$core$String$fromInt(position.aL) + ('-' + $elm$core$String$fromInt(position.cO)))))));
				var modernGrid = _class + ('{' + (modernPosition + '}'));
				var supports = '@supports (display:grid) {' + (modernGrid + '}');
				var base = _class + ('{' + (msPosition + '}'));
				return _List_fromArray(
					[base, supports]);
			case 11:
				var _class = rule.a;
				var styles = rule.b;
				var renderPseudoRule = function (style) {
					return A3(
						$mdgriffith$elm_ui$Internal$Model$renderStyleRule,
						options,
						style,
						$elm$core$Maybe$Just(_class));
				};
				return A2($elm$core$List$concatMap, renderPseudoRule, styles);
			default:
				var transform = rule.a;
				var val = $mdgriffith$elm_ui$Internal$Model$transformValue(transform);
				var _class = $mdgriffith$elm_ui$Internal$Model$transformClass(transform);
				var _v12 = _Utils_Tuple2(_class, val);
				if ((!_v12.a.$) && (!_v12.b.$)) {
					var cls = _v12.a.a;
					var v = _v12.b.a;
					return A4(
						$mdgriffith$elm_ui$Internal$Model$renderStyle,
						options,
						maybePseudo,
						'.' + cls,
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Internal$Model$Property, 'transform', v)
							]));
				} else {
					return _List_Nil;
				}
		}
	});
var $mdgriffith$elm_ui$Internal$Model$encodeStyles = F2(
	function (options, stylesheet) {
		return $elm$json$Json$Encode$object(
			A2(
				$elm$core$List$map,
				function (style) {
					var styled = A3($mdgriffith$elm_ui$Internal$Model$renderStyleRule, options, style, $elm$core$Maybe$Nothing);
					return _Utils_Tuple2(
						$mdgriffith$elm_ui$Internal$Model$getStyleName(style),
						A2($elm$json$Json$Encode$list, $elm$json$Json$Encode$string, styled));
				},
				stylesheet));
	});
var $mdgriffith$elm_ui$Internal$Model$bracket = F2(
	function (selector, rules) {
		var renderPair = function (_v0) {
			var name = _v0.a;
			var val = _v0.b;
			return name + (': ' + (val + ';'));
		};
		return selector + (' {' + (A2(
			$elm$core$String$join,
			'',
			A2($elm$core$List$map, renderPair, rules)) + '}'));
	});
var $mdgriffith$elm_ui$Internal$Model$fontRule = F3(
	function (name, modifier, _v0) {
		var parentAdj = _v0.a;
		var textAdjustment = _v0.b;
		return _List_fromArray(
			[
				A2($mdgriffith$elm_ui$Internal$Model$bracket, '.' + (name + ('.' + (modifier + (', ' + ('.' + (name + (' .' + modifier))))))), parentAdj),
				A2($mdgriffith$elm_ui$Internal$Model$bracket, '.' + (name + ('.' + (modifier + ('> .' + ($mdgriffith$elm_ui$Internal$Style$classes.hN + (', .' + (name + (' .' + (modifier + (' > .' + $mdgriffith$elm_ui$Internal$Style$classes.hN)))))))))), textAdjustment)
			]);
	});
var $mdgriffith$elm_ui$Internal$Model$renderFontAdjustmentRule = F3(
	function (fontToAdjust, _v0, otherFontName) {
		var full = _v0.a;
		var capital = _v0.b;
		var name = _Utils_eq(fontToAdjust, otherFontName) ? fontToAdjust : (otherFontName + (' .' + fontToAdjust));
		return A2(
			$elm$core$String$join,
			' ',
			_Utils_ap(
				A3($mdgriffith$elm_ui$Internal$Model$fontRule, name, $mdgriffith$elm_ui$Internal$Style$classes.hz, capital),
				A3($mdgriffith$elm_ui$Internal$Model$fontRule, name, $mdgriffith$elm_ui$Internal$Style$classes.gz, full)));
	});
var $mdgriffith$elm_ui$Internal$Model$renderNullAdjustmentRule = F2(
	function (fontToAdjust, otherFontName) {
		var name = _Utils_eq(fontToAdjust, otherFontName) ? fontToAdjust : (otherFontName + (' .' + fontToAdjust));
		return A2(
			$elm$core$String$join,
			' ',
			_List_fromArray(
				[
					A2(
					$mdgriffith$elm_ui$Internal$Model$bracket,
					'.' + (name + ('.' + ($mdgriffith$elm_ui$Internal$Style$classes.hz + (', ' + ('.' + (name + (' .' + $mdgriffith$elm_ui$Internal$Style$classes.hz))))))),
					_List_fromArray(
						[
							_Utils_Tuple2('line-height', '1')
						])),
					A2(
					$mdgriffith$elm_ui$Internal$Model$bracket,
					'.' + (name + ('.' + ($mdgriffith$elm_ui$Internal$Style$classes.hz + ('> .' + ($mdgriffith$elm_ui$Internal$Style$classes.hN + (', .' + (name + (' .' + ($mdgriffith$elm_ui$Internal$Style$classes.hz + (' > .' + $mdgriffith$elm_ui$Internal$Style$classes.hN)))))))))),
					_List_fromArray(
						[
							_Utils_Tuple2('vertical-align', '0'),
							_Utils_Tuple2('line-height', '1')
						]))
				]));
	});
var $mdgriffith$elm_ui$Internal$Model$adjust = F3(
	function (size, height, vertical) {
		return {cO: height / size, fn: size, fA: vertical};
	});
var $elm$core$List$maximum = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(
			A3($elm$core$List$foldl, $elm$core$Basics$max, x, xs));
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $elm$core$List$minimum = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(
			A3($elm$core$List$foldl, $elm$core$Basics$min, x, xs));
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $mdgriffith$elm_ui$Internal$Model$convertAdjustment = function (adjustment) {
	var lines = _List_fromArray(
		[adjustment.f7, adjustment.f_, adjustment.gm, adjustment.gU]);
	var lineHeight = 1.5;
	var normalDescender = (lineHeight - 1) / 2;
	var oldMiddle = lineHeight / 2;
	var descender = A2(
		$elm$core$Maybe$withDefault,
		adjustment.gm,
		$elm$core$List$minimum(lines));
	var newBaseline = A2(
		$elm$core$Maybe$withDefault,
		adjustment.f_,
		$elm$core$List$minimum(
			A2(
				$elm$core$List$filter,
				function (x) {
					return !_Utils_eq(x, descender);
				},
				lines)));
	var base = lineHeight;
	var ascender = A2(
		$elm$core$Maybe$withDefault,
		adjustment.f7,
		$elm$core$List$maximum(lines));
	var capitalSize = 1 / (ascender - newBaseline);
	var capitalVertical = 1 - ascender;
	var fullSize = 1 / (ascender - descender);
	var fullVertical = 1 - ascender;
	var newCapitalMiddle = ((ascender - newBaseline) / 2) + newBaseline;
	var newFullMiddle = ((ascender - descender) / 2) + descender;
	return {
		f7: A3($mdgriffith$elm_ui$Internal$Model$adjust, capitalSize, ascender - newBaseline, capitalVertical),
		et: A3($mdgriffith$elm_ui$Internal$Model$adjust, fullSize, ascender - descender, fullVertical)
	};
};
var $mdgriffith$elm_ui$Internal$Model$fontAdjustmentRules = function (converted) {
	return _Utils_Tuple2(
		_List_fromArray(
			[
				_Utils_Tuple2('display', 'block')
			]),
		_List_fromArray(
			[
				_Utils_Tuple2('display', 'inline-block'),
				_Utils_Tuple2(
				'line-height',
				$elm$core$String$fromFloat(converted.cO)),
				_Utils_Tuple2(
				'vertical-align',
				$elm$core$String$fromFloat(converted.fA) + 'em'),
				_Utils_Tuple2(
				'font-size',
				$elm$core$String$fromFloat(converted.fn) + 'em')
			]));
};
var $mdgriffith$elm_ui$Internal$Model$typefaceAdjustment = function (typefaces) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (face, found) {
				if (found.$ === 1) {
					if (face.$ === 5) {
						var _with = face.a;
						var _v2 = _with.fK;
						if (_v2.$ === 1) {
							return found;
						} else {
							var adjustment = _v2.a;
							return $elm$core$Maybe$Just(
								_Utils_Tuple2(
									$mdgriffith$elm_ui$Internal$Model$fontAdjustmentRules(
										function ($) {
											return $.et;
										}(
											$mdgriffith$elm_ui$Internal$Model$convertAdjustment(adjustment))),
									$mdgriffith$elm_ui$Internal$Model$fontAdjustmentRules(
										function ($) {
											return $.f7;
										}(
											$mdgriffith$elm_ui$Internal$Model$convertAdjustment(adjustment)))));
						}
					} else {
						return found;
					}
				} else {
					return found;
				}
			}),
		$elm$core$Maybe$Nothing,
		typefaces);
};
var $mdgriffith$elm_ui$Internal$Model$renderTopLevelValues = function (rules) {
	var withImport = function (font) {
		if (font.$ === 4) {
			var url = font.b;
			return $elm$core$Maybe$Just('@import url(\'' + (url + '\');'));
		} else {
			return $elm$core$Maybe$Nothing;
		}
	};
	var fontImports = function (_v2) {
		var name = _v2.a;
		var typefaces = _v2.b;
		var imports = A2(
			$elm$core$String$join,
			'\n',
			A2($elm$core$List$filterMap, withImport, typefaces));
		return imports;
	};
	var allNames = A2($elm$core$List$map, $elm$core$Tuple$first, rules);
	var fontAdjustments = function (_v1) {
		var name = _v1.a;
		var typefaces = _v1.b;
		var _v0 = $mdgriffith$elm_ui$Internal$Model$typefaceAdjustment(typefaces);
		if (_v0.$ === 1) {
			return A2(
				$elm$core$String$join,
				'',
				A2(
					$elm$core$List$map,
					$mdgriffith$elm_ui$Internal$Model$renderNullAdjustmentRule(name),
					allNames));
		} else {
			var adjustment = _v0.a;
			return A2(
				$elm$core$String$join,
				'',
				A2(
					$elm$core$List$map,
					A2($mdgriffith$elm_ui$Internal$Model$renderFontAdjustmentRule, name, adjustment),
					allNames));
		}
	};
	return _Utils_ap(
		A2(
			$elm$core$String$join,
			'\n',
			A2($elm$core$List$map, fontImports, rules)),
		A2(
			$elm$core$String$join,
			'\n',
			A2($elm$core$List$map, fontAdjustments, rules)));
};
var $mdgriffith$elm_ui$Internal$Model$topLevelValue = function (rule) {
	if (rule.$ === 1) {
		var name = rule.a;
		var typefaces = rule.b;
		return $elm$core$Maybe$Just(
			_Utils_Tuple2(name, typefaces));
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $mdgriffith$elm_ui$Internal$Model$toStyleSheetString = F2(
	function (options, stylesheet) {
		var combine = F2(
			function (style, rendered) {
				return {
					ck: _Utils_ap(
						rendered.ck,
						A3($mdgriffith$elm_ui$Internal$Model$renderStyleRule, options, style, $elm$core$Maybe$Nothing)),
					bS: function () {
						var _v1 = $mdgriffith$elm_ui$Internal$Model$topLevelValue(style);
						if (_v1.$ === 1) {
							return rendered.bS;
						} else {
							var topLevel = _v1.a;
							return A2($elm$core$List$cons, topLevel, rendered.bS);
						}
					}()
				};
			});
		var _v0 = A3(
			$elm$core$List$foldl,
			combine,
			{ck: _List_Nil, bS: _List_Nil},
			stylesheet);
		var topLevel = _v0.bS;
		var rules = _v0.ck;
		return _Utils_ap(
			$mdgriffith$elm_ui$Internal$Model$renderTopLevelValues(topLevel),
			$elm$core$String$concat(rules));
	});
var $mdgriffith$elm_ui$Internal$Model$toStyleSheet = F2(
	function (options, styleSheet) {
		var _v0 = options.gY;
		switch (_v0) {
			case 0:
				return A3(
					$elm$virtual_dom$VirtualDom$node,
					'div',
					_List_Nil,
					_List_fromArray(
						[
							A3(
							$elm$virtual_dom$VirtualDom$node,
							'style',
							_List_Nil,
							_List_fromArray(
								[
									$elm$virtual_dom$VirtualDom$text(
									A2($mdgriffith$elm_ui$Internal$Model$toStyleSheetString, options, styleSheet))
								]))
						]));
			case 1:
				return A3(
					$elm$virtual_dom$VirtualDom$node,
					'div',
					_List_Nil,
					_List_fromArray(
						[
							A3(
							$elm$virtual_dom$VirtualDom$node,
							'style',
							_List_Nil,
							_List_fromArray(
								[
									$elm$virtual_dom$VirtualDom$text(
									A2($mdgriffith$elm_ui$Internal$Model$toStyleSheetString, options, styleSheet))
								]))
						]));
			default:
				return A3(
					$elm$virtual_dom$VirtualDom$node,
					'elm-ui-rules',
					_List_fromArray(
						[
							A2(
							$elm$virtual_dom$VirtualDom$property,
							'rules',
							A2($mdgriffith$elm_ui$Internal$Model$encodeStyles, options, styleSheet))
						]),
					_List_Nil);
		}
	});
var $mdgriffith$elm_ui$Internal$Model$embedKeyed = F4(
	function (_static, opts, styles, children) {
		var dynamicStyleSheet = A2(
			$mdgriffith$elm_ui$Internal$Model$toStyleSheet,
			opts,
			A3(
				$elm$core$List$foldl,
				$mdgriffith$elm_ui$Internal$Model$reduceStyles,
				_Utils_Tuple2(
					$elm$core$Set$empty,
					$mdgriffith$elm_ui$Internal$Model$renderFocusStyle(opts.gx)),
				styles).b);
		return _static ? A2(
			$elm$core$List$cons,
			_Utils_Tuple2(
				'static-stylesheet',
				$mdgriffith$elm_ui$Internal$Model$staticRoot(opts)),
			A2(
				$elm$core$List$cons,
				_Utils_Tuple2('dynamic-stylesheet', dynamicStyleSheet),
				children)) : A2(
			$elm$core$List$cons,
			_Utils_Tuple2('dynamic-stylesheet', dynamicStyleSheet),
			children);
	});
var $mdgriffith$elm_ui$Internal$Model$embedWith = F4(
	function (_static, opts, styles, children) {
		var dynamicStyleSheet = A2(
			$mdgriffith$elm_ui$Internal$Model$toStyleSheet,
			opts,
			A3(
				$elm$core$List$foldl,
				$mdgriffith$elm_ui$Internal$Model$reduceStyles,
				_Utils_Tuple2(
					$elm$core$Set$empty,
					$mdgriffith$elm_ui$Internal$Model$renderFocusStyle(opts.gx)),
				styles).b);
		return _static ? A2(
			$elm$core$List$cons,
			$mdgriffith$elm_ui$Internal$Model$staticRoot(opts),
			A2($elm$core$List$cons, dynamicStyleSheet, children)) : A2($elm$core$List$cons, dynamicStyleSheet, children);
	});
var $mdgriffith$elm_ui$Internal$Flag$heightBetween = $mdgriffith$elm_ui$Internal$Flag$flag(45);
var $mdgriffith$elm_ui$Internal$Flag$heightFill = $mdgriffith$elm_ui$Internal$Flag$flag(37);
var $elm$virtual_dom$VirtualDom$keyedNode = function (tag) {
	return _VirtualDom_keyedNode(
		_VirtualDom_noScript(tag));
};
var $elm$html$Html$p = _VirtualDom_node('p');
var $elm$core$Bitwise$and = _Bitwise_and;
var $mdgriffith$elm_ui$Internal$Flag$present = F2(
	function (myFlag, _v0) {
		var fieldOne = _v0.a;
		var fieldTwo = _v0.b;
		if (!myFlag.$) {
			var first = myFlag.a;
			return _Utils_eq(first & fieldOne, first);
		} else {
			var second = myFlag.a;
			return _Utils_eq(second & fieldTwo, second);
		}
	});
var $elm$html$Html$s = _VirtualDom_node('s');
var $elm$html$Html$u = _VirtualDom_node('u');
var $mdgriffith$elm_ui$Internal$Flag$widthBetween = $mdgriffith$elm_ui$Internal$Flag$flag(44);
var $mdgriffith$elm_ui$Internal$Flag$widthFill = $mdgriffith$elm_ui$Internal$Flag$flag(39);
var $mdgriffith$elm_ui$Internal$Model$finalizeNode = F6(
	function (has, node, attributes, children, embedMode, parentContext) {
		var createNode = F2(
			function (nodeName, attrs) {
				if (children.$ === 1) {
					var keyed = children.a;
					return A3(
						$elm$virtual_dom$VirtualDom$keyedNode,
						nodeName,
						attrs,
						function () {
							switch (embedMode.$) {
								case 0:
									return keyed;
								case 2:
									var opts = embedMode.a;
									var styles = embedMode.b;
									return A4($mdgriffith$elm_ui$Internal$Model$embedKeyed, false, opts, styles, keyed);
								default:
									var opts = embedMode.a;
									var styles = embedMode.b;
									return A4($mdgriffith$elm_ui$Internal$Model$embedKeyed, true, opts, styles, keyed);
							}
						}());
				} else {
					var unkeyed = children.a;
					return A2(
						function () {
							switch (nodeName) {
								case 'div':
									return $elm$html$Html$div;
								case 'p':
									return $elm$html$Html$p;
								default:
									return $elm$virtual_dom$VirtualDom$node(nodeName);
							}
						}(),
						attrs,
						function () {
							switch (embedMode.$) {
								case 0:
									return unkeyed;
								case 2:
									var opts = embedMode.a;
									var styles = embedMode.b;
									return A4($mdgriffith$elm_ui$Internal$Model$embedWith, false, opts, styles, unkeyed);
								default:
									var opts = embedMode.a;
									var styles = embedMode.b;
									return A4($mdgriffith$elm_ui$Internal$Model$embedWith, true, opts, styles, unkeyed);
							}
						}());
				}
			});
		var html = function () {
			switch (node.$) {
				case 0:
					return A2(createNode, 'div', attributes);
				case 1:
					var nodeName = node.a;
					return A2(createNode, nodeName, attributes);
				default:
					var nodeName = node.a;
					var internal = node.b;
					return A3(
						$elm$virtual_dom$VirtualDom$node,
						nodeName,
						attributes,
						_List_fromArray(
							[
								A2(
								createNode,
								internal,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class($mdgriffith$elm_ui$Internal$Style$classes.fV + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.hy))
									]))
							]));
			}
		}();
		switch (parentContext) {
			case 0:
				return (A2($mdgriffith$elm_ui$Internal$Flag$present, $mdgriffith$elm_ui$Internal$Flag$widthFill, has) && (!A2($mdgriffith$elm_ui$Internal$Flag$present, $mdgriffith$elm_ui$Internal$Flag$widthBetween, has))) ? html : (A2($mdgriffith$elm_ui$Internal$Flag$present, $mdgriffith$elm_ui$Internal$Flag$alignRight, has) ? A2(
					$elm$html$Html$u,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class(
							A2(
								$elm$core$String$join,
								' ',
								_List_fromArray(
									[$mdgriffith$elm_ui$Internal$Style$classes.fV, $mdgriffith$elm_ui$Internal$Style$classes.hy, $mdgriffith$elm_ui$Internal$Style$classes.b3, $mdgriffith$elm_ui$Internal$Style$classes.aw, $mdgriffith$elm_ui$Internal$Style$classes.fR])))
						]),
					_List_fromArray(
						[html])) : (A2($mdgriffith$elm_ui$Internal$Flag$present, $mdgriffith$elm_ui$Internal$Flag$centerX, has) ? A2(
					$elm$html$Html$s,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class(
							A2(
								$elm$core$String$join,
								' ',
								_List_fromArray(
									[$mdgriffith$elm_ui$Internal$Style$classes.fV, $mdgriffith$elm_ui$Internal$Style$classes.hy, $mdgriffith$elm_ui$Internal$Style$classes.b3, $mdgriffith$elm_ui$Internal$Style$classes.aw, $mdgriffith$elm_ui$Internal$Style$classes.fP])))
						]),
					_List_fromArray(
						[html])) : html));
			case 1:
				return (A2($mdgriffith$elm_ui$Internal$Flag$present, $mdgriffith$elm_ui$Internal$Flag$heightFill, has) && (!A2($mdgriffith$elm_ui$Internal$Flag$present, $mdgriffith$elm_ui$Internal$Flag$heightBetween, has))) ? html : (A2($mdgriffith$elm_ui$Internal$Flag$present, $mdgriffith$elm_ui$Internal$Flag$centerY, has) ? A2(
					$elm$html$Html$s,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class(
							A2(
								$elm$core$String$join,
								' ',
								_List_fromArray(
									[$mdgriffith$elm_ui$Internal$Style$classes.fV, $mdgriffith$elm_ui$Internal$Style$classes.hy, $mdgriffith$elm_ui$Internal$Style$classes.b3, $mdgriffith$elm_ui$Internal$Style$classes.fQ])))
						]),
					_List_fromArray(
						[html])) : (A2($mdgriffith$elm_ui$Internal$Flag$present, $mdgriffith$elm_ui$Internal$Flag$alignBottom, has) ? A2(
					$elm$html$Html$u,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class(
							A2(
								$elm$core$String$join,
								' ',
								_List_fromArray(
									[$mdgriffith$elm_ui$Internal$Style$classes.fV, $mdgriffith$elm_ui$Internal$Style$classes.hy, $mdgriffith$elm_ui$Internal$Style$classes.b3, $mdgriffith$elm_ui$Internal$Style$classes.fO])))
						]),
					_List_fromArray(
						[html])) : html));
			default:
				return html;
		}
	});
var $elm$html$Html$text = $elm$virtual_dom$VirtualDom$text;
var $mdgriffith$elm_ui$Internal$Model$textElementClasses = $mdgriffith$elm_ui$Internal$Style$classes.fV + (' ' + ($mdgriffith$elm_ui$Internal$Style$classes.hN + (' ' + ($mdgriffith$elm_ui$Internal$Style$classes.dW + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.cP)))));
var $mdgriffith$elm_ui$Internal$Model$textElement = function (str) {
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class($mdgriffith$elm_ui$Internal$Model$textElementClasses)
			]),
		_List_fromArray(
			[
				$elm$html$Html$text(str)
			]));
};
var $mdgriffith$elm_ui$Internal$Model$textElementFillClasses = $mdgriffith$elm_ui$Internal$Style$classes.fV + (' ' + ($mdgriffith$elm_ui$Internal$Style$classes.hN + (' ' + ($mdgriffith$elm_ui$Internal$Style$classes.dX + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.cQ)))));
var $mdgriffith$elm_ui$Internal$Model$textElementFill = function (str) {
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class($mdgriffith$elm_ui$Internal$Model$textElementFillClasses)
			]),
		_List_fromArray(
			[
				$elm$html$Html$text(str)
			]));
};
var $mdgriffith$elm_ui$Internal$Model$createElement = F3(
	function (context, children, rendered) {
		var gatherKeyed = F2(
			function (_v8, _v9) {
				var key = _v8.a;
				var child = _v8.b;
				var htmls = _v9.a;
				var existingStyles = _v9.b;
				switch (child.$) {
					case 0:
						var html = child.a;
						return _Utils_eq(context, $mdgriffith$elm_ui$Internal$Model$asParagraph) ? _Utils_Tuple2(
							A2(
								$elm$core$List$cons,
								_Utils_Tuple2(
									key,
									html(context)),
								htmls),
							existingStyles) : _Utils_Tuple2(
							A2(
								$elm$core$List$cons,
								_Utils_Tuple2(
									key,
									html(context)),
								htmls),
							existingStyles);
					case 1:
						var styled = child.a;
						return _Utils_eq(context, $mdgriffith$elm_ui$Internal$Model$asParagraph) ? _Utils_Tuple2(
							A2(
								$elm$core$List$cons,
								_Utils_Tuple2(
									key,
									A2(styled.gE, $mdgriffith$elm_ui$Internal$Model$NoStyleSheet, context)),
								htmls),
							$elm$core$List$isEmpty(existingStyles) ? styled.hJ : _Utils_ap(styled.hJ, existingStyles)) : _Utils_Tuple2(
							A2(
								$elm$core$List$cons,
								_Utils_Tuple2(
									key,
									A2(styled.gE, $mdgriffith$elm_ui$Internal$Model$NoStyleSheet, context)),
								htmls),
							$elm$core$List$isEmpty(existingStyles) ? styled.hJ : _Utils_ap(styled.hJ, existingStyles));
					case 2:
						var str = child.a;
						return _Utils_Tuple2(
							A2(
								$elm$core$List$cons,
								_Utils_Tuple2(
									key,
									_Utils_eq(context, $mdgriffith$elm_ui$Internal$Model$asEl) ? $mdgriffith$elm_ui$Internal$Model$textElementFill(str) : $mdgriffith$elm_ui$Internal$Model$textElement(str)),
								htmls),
							existingStyles);
					default:
						return _Utils_Tuple2(htmls, existingStyles);
				}
			});
		var gather = F2(
			function (child, _v6) {
				var htmls = _v6.a;
				var existingStyles = _v6.b;
				switch (child.$) {
					case 0:
						var html = child.a;
						return _Utils_eq(context, $mdgriffith$elm_ui$Internal$Model$asParagraph) ? _Utils_Tuple2(
							A2(
								$elm$core$List$cons,
								html(context),
								htmls),
							existingStyles) : _Utils_Tuple2(
							A2(
								$elm$core$List$cons,
								html(context),
								htmls),
							existingStyles);
					case 1:
						var styled = child.a;
						return _Utils_eq(context, $mdgriffith$elm_ui$Internal$Model$asParagraph) ? _Utils_Tuple2(
							A2(
								$elm$core$List$cons,
								A2(styled.gE, $mdgriffith$elm_ui$Internal$Model$NoStyleSheet, context),
								htmls),
							$elm$core$List$isEmpty(existingStyles) ? styled.hJ : _Utils_ap(styled.hJ, existingStyles)) : _Utils_Tuple2(
							A2(
								$elm$core$List$cons,
								A2(styled.gE, $mdgriffith$elm_ui$Internal$Model$NoStyleSheet, context),
								htmls),
							$elm$core$List$isEmpty(existingStyles) ? styled.hJ : _Utils_ap(styled.hJ, existingStyles));
					case 2:
						var str = child.a;
						return _Utils_Tuple2(
							A2(
								$elm$core$List$cons,
								_Utils_eq(context, $mdgriffith$elm_ui$Internal$Model$asEl) ? $mdgriffith$elm_ui$Internal$Model$textElementFill(str) : $mdgriffith$elm_ui$Internal$Model$textElement(str),
								htmls),
							existingStyles);
					default:
						return _Utils_Tuple2(htmls, existingStyles);
				}
			});
		if (children.$ === 1) {
			var keyedChildren = children.a;
			var _v1 = A3(
				$elm$core$List$foldr,
				gatherKeyed,
				_Utils_Tuple2(_List_Nil, _List_Nil),
				keyedChildren);
			var keyed = _v1.a;
			var styles = _v1.b;
			var newStyles = $elm$core$List$isEmpty(styles) ? rendered.hJ : _Utils_ap(rendered.hJ, styles);
			if (!newStyles.b) {
				return $mdgriffith$elm_ui$Internal$Model$Unstyled(
					A5(
						$mdgriffith$elm_ui$Internal$Model$finalizeNode,
						rendered.aS,
						rendered.aU,
						rendered.bY,
						$mdgriffith$elm_ui$Internal$Model$Keyed(
							A3($mdgriffith$elm_ui$Internal$Model$addKeyedChildren, 'nearby-element-pls', keyed, rendered.ga)),
						$mdgriffith$elm_ui$Internal$Model$NoStyleSheet));
			} else {
				var allStyles = newStyles;
				return $mdgriffith$elm_ui$Internal$Model$Styled(
					{
						gE: A4(
							$mdgriffith$elm_ui$Internal$Model$finalizeNode,
							rendered.aS,
							rendered.aU,
							rendered.bY,
							$mdgriffith$elm_ui$Internal$Model$Keyed(
								A3($mdgriffith$elm_ui$Internal$Model$addKeyedChildren, 'nearby-element-pls', keyed, rendered.ga))),
						hJ: allStyles
					});
			}
		} else {
			var unkeyedChildren = children.a;
			var _v3 = A3(
				$elm$core$List$foldr,
				gather,
				_Utils_Tuple2(_List_Nil, _List_Nil),
				unkeyedChildren);
			var unkeyed = _v3.a;
			var styles = _v3.b;
			var newStyles = $elm$core$List$isEmpty(styles) ? rendered.hJ : _Utils_ap(rendered.hJ, styles);
			if (!newStyles.b) {
				return $mdgriffith$elm_ui$Internal$Model$Unstyled(
					A5(
						$mdgriffith$elm_ui$Internal$Model$finalizeNode,
						rendered.aS,
						rendered.aU,
						rendered.bY,
						$mdgriffith$elm_ui$Internal$Model$Unkeyed(
							A2($mdgriffith$elm_ui$Internal$Model$addChildren, unkeyed, rendered.ga)),
						$mdgriffith$elm_ui$Internal$Model$NoStyleSheet));
			} else {
				var allStyles = newStyles;
				return $mdgriffith$elm_ui$Internal$Model$Styled(
					{
						gE: A4(
							$mdgriffith$elm_ui$Internal$Model$finalizeNode,
							rendered.aS,
							rendered.aU,
							rendered.bY,
							$mdgriffith$elm_ui$Internal$Model$Unkeyed(
								A2($mdgriffith$elm_ui$Internal$Model$addChildren, unkeyed, rendered.ga))),
						hJ: allStyles
					});
			}
		}
	});
var $mdgriffith$elm_ui$Internal$Model$Single = F3(
	function (a, b, c) {
		return {$: 3, a: a, b: b, c: c};
	});
var $mdgriffith$elm_ui$Internal$Model$Transform = function (a) {
	return {$: 10, a: a};
};
var $mdgriffith$elm_ui$Internal$Flag$Field = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $elm$core$Bitwise$or = _Bitwise_or;
var $mdgriffith$elm_ui$Internal$Flag$add = F2(
	function (myFlag, _v0) {
		var one = _v0.a;
		var two = _v0.b;
		if (!myFlag.$) {
			var first = myFlag.a;
			return A2($mdgriffith$elm_ui$Internal$Flag$Field, first | one, two);
		} else {
			var second = myFlag.a;
			return A2($mdgriffith$elm_ui$Internal$Flag$Field, one, second | two);
		}
	});
var $mdgriffith$elm_ui$Internal$Model$ChildrenBehind = function (a) {
	return {$: 1, a: a};
};
var $mdgriffith$elm_ui$Internal$Model$ChildrenBehindAndInFront = F2(
	function (a, b) {
		return {$: 3, a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Model$ChildrenInFront = function (a) {
	return {$: 2, a: a};
};
var $mdgriffith$elm_ui$Internal$Model$nearbyElement = F2(
	function (location, elem) {
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class(
					function () {
						switch (location) {
							case 0:
								return A2(
									$elm$core$String$join,
									' ',
									_List_fromArray(
										[$mdgriffith$elm_ui$Internal$Style$classes.bd, $mdgriffith$elm_ui$Internal$Style$classes.hy, $mdgriffith$elm_ui$Internal$Style$classes.fJ]));
							case 1:
								return A2(
									$elm$core$String$join,
									' ',
									_List_fromArray(
										[$mdgriffith$elm_ui$Internal$Style$classes.bd, $mdgriffith$elm_ui$Internal$Style$classes.hy, $mdgriffith$elm_ui$Internal$Style$classes.f0]));
							case 2:
								return A2(
									$elm$core$String$join,
									' ',
									_List_fromArray(
										[$mdgriffith$elm_ui$Internal$Style$classes.bd, $mdgriffith$elm_ui$Internal$Style$classes.hy, $mdgriffith$elm_ui$Internal$Style$classes.g4]));
							case 3:
								return A2(
									$elm$core$String$join,
									' ',
									_List_fromArray(
										[$mdgriffith$elm_ui$Internal$Style$classes.bd, $mdgriffith$elm_ui$Internal$Style$classes.hy, $mdgriffith$elm_ui$Internal$Style$classes.g3]));
							case 4:
								return A2(
									$elm$core$String$join,
									' ',
									_List_fromArray(
										[$mdgriffith$elm_ui$Internal$Style$classes.bd, $mdgriffith$elm_ui$Internal$Style$classes.hy, $mdgriffith$elm_ui$Internal$Style$classes.gH]));
							default:
								return A2(
									$elm$core$String$join,
									' ',
									_List_fromArray(
										[$mdgriffith$elm_ui$Internal$Style$classes.bd, $mdgriffith$elm_ui$Internal$Style$classes.hy, $mdgriffith$elm_ui$Internal$Style$classes.f$]));
						}
					}())
				]),
			_List_fromArray(
				[
					function () {
					switch (elem.$) {
						case 3:
							return $elm$virtual_dom$VirtualDom$text('');
						case 2:
							var str = elem.a;
							return $mdgriffith$elm_ui$Internal$Model$textElement(str);
						case 0:
							var html = elem.a;
							return html($mdgriffith$elm_ui$Internal$Model$asEl);
						default:
							var styled = elem.a;
							return A2(styled.gE, $mdgriffith$elm_ui$Internal$Model$NoStyleSheet, $mdgriffith$elm_ui$Internal$Model$asEl);
					}
				}()
				]));
	});
var $mdgriffith$elm_ui$Internal$Model$addNearbyElement = F3(
	function (location, elem, existing) {
		var nearby = A2($mdgriffith$elm_ui$Internal$Model$nearbyElement, location, elem);
		switch (existing.$) {
			case 0:
				if (location === 5) {
					return $mdgriffith$elm_ui$Internal$Model$ChildrenBehind(
						_List_fromArray(
							[nearby]));
				} else {
					return $mdgriffith$elm_ui$Internal$Model$ChildrenInFront(
						_List_fromArray(
							[nearby]));
				}
			case 1:
				var existingBehind = existing.a;
				if (location === 5) {
					return $mdgriffith$elm_ui$Internal$Model$ChildrenBehind(
						A2($elm$core$List$cons, nearby, existingBehind));
				} else {
					return A2(
						$mdgriffith$elm_ui$Internal$Model$ChildrenBehindAndInFront,
						existingBehind,
						_List_fromArray(
							[nearby]));
				}
			case 2:
				var existingInFront = existing.a;
				if (location === 5) {
					return A2(
						$mdgriffith$elm_ui$Internal$Model$ChildrenBehindAndInFront,
						_List_fromArray(
							[nearby]),
						existingInFront);
				} else {
					return $mdgriffith$elm_ui$Internal$Model$ChildrenInFront(
						A2($elm$core$List$cons, nearby, existingInFront));
				}
			default:
				var existingBehind = existing.a;
				var existingInFront = existing.b;
				if (location === 5) {
					return A2(
						$mdgriffith$elm_ui$Internal$Model$ChildrenBehindAndInFront,
						A2($elm$core$List$cons, nearby, existingBehind),
						existingInFront);
				} else {
					return A2(
						$mdgriffith$elm_ui$Internal$Model$ChildrenBehindAndInFront,
						existingBehind,
						A2($elm$core$List$cons, nearby, existingInFront));
				}
		}
	});
var $mdgriffith$elm_ui$Internal$Model$Embedded = F2(
	function (a, b) {
		return {$: 2, a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Model$NodeName = function (a) {
	return {$: 1, a: a};
};
var $mdgriffith$elm_ui$Internal$Model$addNodeName = F2(
	function (newNode, old) {
		switch (old.$) {
			case 0:
				return $mdgriffith$elm_ui$Internal$Model$NodeName(newNode);
			case 1:
				var name = old.a;
				return A2($mdgriffith$elm_ui$Internal$Model$Embedded, name, newNode);
			default:
				var x = old.a;
				var y = old.b;
				return A2($mdgriffith$elm_ui$Internal$Model$Embedded, x, y);
		}
	});
var $mdgriffith$elm_ui$Internal$Model$alignXName = function (align) {
	switch (align) {
		case 0:
			return $mdgriffith$elm_ui$Internal$Style$classes.cu + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.d7);
		case 2:
			return $mdgriffith$elm_ui$Internal$Style$classes.cu + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.d8);
		default:
			return $mdgriffith$elm_ui$Internal$Style$classes.cu + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.fM);
	}
};
var $mdgriffith$elm_ui$Internal$Model$alignYName = function (align) {
	switch (align) {
		case 0:
			return $mdgriffith$elm_ui$Internal$Style$classes.cv + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.fS);
		case 2:
			return $mdgriffith$elm_ui$Internal$Style$classes.cv + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.fL);
		default:
			return $mdgriffith$elm_ui$Internal$Style$classes.cv + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.fN);
	}
};
var $elm$virtual_dom$VirtualDom$attribute = F2(
	function (key, value) {
		return A2(
			_VirtualDom_attribute,
			_VirtualDom_noOnOrFormAction(key),
			_VirtualDom_noJavaScriptOrHtmlUri(value));
	});
var $mdgriffith$elm_ui$Internal$Model$FullTransform = F4(
	function (a, b, c, d) {
		return {$: 2, a: a, b: b, c: c, d: d};
	});
var $mdgriffith$elm_ui$Internal$Model$Moved = function (a) {
	return {$: 1, a: a};
};
var $mdgriffith$elm_ui$Internal$Model$composeTransformation = F2(
	function (transform, component) {
		switch (transform.$) {
			case 0:
				switch (component.$) {
					case 0:
						var x = component.a;
						return $mdgriffith$elm_ui$Internal$Model$Moved(
							_Utils_Tuple3(x, 0, 0));
					case 1:
						var y = component.a;
						return $mdgriffith$elm_ui$Internal$Model$Moved(
							_Utils_Tuple3(0, y, 0));
					case 2:
						var z = component.a;
						return $mdgriffith$elm_ui$Internal$Model$Moved(
							_Utils_Tuple3(0, 0, z));
					case 3:
						var xyz = component.a;
						return $mdgriffith$elm_ui$Internal$Model$Moved(xyz);
					case 4:
						var xyz = component.a;
						var angle = component.b;
						return A4(
							$mdgriffith$elm_ui$Internal$Model$FullTransform,
							_Utils_Tuple3(0, 0, 0),
							_Utils_Tuple3(1, 1, 1),
							xyz,
							angle);
					default:
						var xyz = component.a;
						return A4(
							$mdgriffith$elm_ui$Internal$Model$FullTransform,
							_Utils_Tuple3(0, 0, 0),
							xyz,
							_Utils_Tuple3(0, 0, 1),
							0);
				}
			case 1:
				var moved = transform.a;
				var x = moved.a;
				var y = moved.b;
				var z = moved.c;
				switch (component.$) {
					case 0:
						var newX = component.a;
						return $mdgriffith$elm_ui$Internal$Model$Moved(
							_Utils_Tuple3(newX, y, z));
					case 1:
						var newY = component.a;
						return $mdgriffith$elm_ui$Internal$Model$Moved(
							_Utils_Tuple3(x, newY, z));
					case 2:
						var newZ = component.a;
						return $mdgriffith$elm_ui$Internal$Model$Moved(
							_Utils_Tuple3(x, y, newZ));
					case 3:
						var xyz = component.a;
						return $mdgriffith$elm_ui$Internal$Model$Moved(xyz);
					case 4:
						var xyz = component.a;
						var angle = component.b;
						return A4(
							$mdgriffith$elm_ui$Internal$Model$FullTransform,
							moved,
							_Utils_Tuple3(1, 1, 1),
							xyz,
							angle);
					default:
						var scale = component.a;
						return A4(
							$mdgriffith$elm_ui$Internal$Model$FullTransform,
							moved,
							scale,
							_Utils_Tuple3(0, 0, 1),
							0);
				}
			default:
				var moved = transform.a;
				var x = moved.a;
				var y = moved.b;
				var z = moved.c;
				var scaled = transform.b;
				var origin = transform.c;
				var angle = transform.d;
				switch (component.$) {
					case 0:
						var newX = component.a;
						return A4(
							$mdgriffith$elm_ui$Internal$Model$FullTransform,
							_Utils_Tuple3(newX, y, z),
							scaled,
							origin,
							angle);
					case 1:
						var newY = component.a;
						return A4(
							$mdgriffith$elm_ui$Internal$Model$FullTransform,
							_Utils_Tuple3(x, newY, z),
							scaled,
							origin,
							angle);
					case 2:
						var newZ = component.a;
						return A4(
							$mdgriffith$elm_ui$Internal$Model$FullTransform,
							_Utils_Tuple3(x, y, newZ),
							scaled,
							origin,
							angle);
					case 3:
						var newMove = component.a;
						return A4($mdgriffith$elm_ui$Internal$Model$FullTransform, newMove, scaled, origin, angle);
					case 4:
						var newOrigin = component.a;
						var newAngle = component.b;
						return A4($mdgriffith$elm_ui$Internal$Model$FullTransform, moved, scaled, newOrigin, newAngle);
					default:
						var newScale = component.a;
						return A4($mdgriffith$elm_ui$Internal$Model$FullTransform, moved, newScale, origin, angle);
				}
		}
	});
var $mdgriffith$elm_ui$Internal$Flag$height = $mdgriffith$elm_ui$Internal$Flag$flag(7);
var $mdgriffith$elm_ui$Internal$Flag$heightContent = $mdgriffith$elm_ui$Internal$Flag$flag(36);
var $mdgriffith$elm_ui$Internal$Flag$merge = F2(
	function (_v0, _v1) {
		var one = _v0.a;
		var two = _v0.b;
		var three = _v1.a;
		var four = _v1.b;
		return A2($mdgriffith$elm_ui$Internal$Flag$Field, one | three, two | four);
	});
var $mdgriffith$elm_ui$Internal$Flag$none = A2($mdgriffith$elm_ui$Internal$Flag$Field, 0, 0);
var $mdgriffith$elm_ui$Internal$Model$renderHeight = function (h) {
	switch (h.$) {
		case 0:
			var px = h.a;
			var val = $elm$core$String$fromInt(px);
			var name = 'height-px-' + val;
			return _Utils_Tuple3(
				$mdgriffith$elm_ui$Internal$Flag$none,
				$mdgriffith$elm_ui$Internal$Style$classes.ev + (' ' + name),
				_List_fromArray(
					[
						A3($mdgriffith$elm_ui$Internal$Model$Single, name, 'height', val + 'px')
					]));
		case 1:
			return _Utils_Tuple3(
				A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$heightContent, $mdgriffith$elm_ui$Internal$Flag$none),
				$mdgriffith$elm_ui$Internal$Style$classes.cP,
				_List_Nil);
		case 2:
			var portion = h.a;
			return (portion === 1) ? _Utils_Tuple3(
				A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$heightFill, $mdgriffith$elm_ui$Internal$Flag$none),
				$mdgriffith$elm_ui$Internal$Style$classes.cQ,
				_List_Nil) : _Utils_Tuple3(
				A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$heightFill, $mdgriffith$elm_ui$Internal$Flag$none),
				$mdgriffith$elm_ui$Internal$Style$classes.ew + (' height-fill-' + $elm$core$String$fromInt(portion)),
				_List_fromArray(
					[
						A3(
						$mdgriffith$elm_ui$Internal$Model$Single,
						$mdgriffith$elm_ui$Internal$Style$classes.fV + ('.' + ($mdgriffith$elm_ui$Internal$Style$classes.av + (' > ' + $mdgriffith$elm_ui$Internal$Style$dot(
							'height-fill-' + $elm$core$String$fromInt(portion))))),
						'flex-grow',
						$elm$core$String$fromInt(portion * 100000))
					]));
		case 3:
			var minSize = h.a;
			var len = h.b;
			var cls = 'min-height-' + $elm$core$String$fromInt(minSize);
			var style = A3(
				$mdgriffith$elm_ui$Internal$Model$Single,
				cls,
				'min-height',
				$elm$core$String$fromInt(minSize) + 'px !important');
			var _v1 = $mdgriffith$elm_ui$Internal$Model$renderHeight(len);
			var newFlag = _v1.a;
			var newAttrs = _v1.b;
			var newStyle = _v1.c;
			return _Utils_Tuple3(
				A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$heightBetween, newFlag),
				cls + (' ' + newAttrs),
				A2($elm$core$List$cons, style, newStyle));
		default:
			var maxSize = h.a;
			var len = h.b;
			var cls = 'max-height-' + $elm$core$String$fromInt(maxSize);
			var style = A3(
				$mdgriffith$elm_ui$Internal$Model$Single,
				cls,
				'max-height',
				$elm$core$String$fromInt(maxSize) + 'px');
			var _v2 = $mdgriffith$elm_ui$Internal$Model$renderHeight(len);
			var newFlag = _v2.a;
			var newAttrs = _v2.b;
			var newStyle = _v2.c;
			return _Utils_Tuple3(
				A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$heightBetween, newFlag),
				cls + (' ' + newAttrs),
				A2($elm$core$List$cons, style, newStyle));
	}
};
var $mdgriffith$elm_ui$Internal$Flag$widthContent = $mdgriffith$elm_ui$Internal$Flag$flag(38);
var $mdgriffith$elm_ui$Internal$Model$renderWidth = function (w) {
	switch (w.$) {
		case 0:
			var px = w.a;
			return _Utils_Tuple3(
				$mdgriffith$elm_ui$Internal$Flag$none,
				$mdgriffith$elm_ui$Internal$Style$classes.fE + (' width-px-' + $elm$core$String$fromInt(px)),
				_List_fromArray(
					[
						A3(
						$mdgriffith$elm_ui$Internal$Model$Single,
						'width-px-' + $elm$core$String$fromInt(px),
						'width',
						$elm$core$String$fromInt(px) + 'px')
					]));
		case 1:
			return _Utils_Tuple3(
				A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$widthContent, $mdgriffith$elm_ui$Internal$Flag$none),
				$mdgriffith$elm_ui$Internal$Style$classes.dW,
				_List_Nil);
		case 2:
			var portion = w.a;
			return (portion === 1) ? _Utils_Tuple3(
				A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$widthFill, $mdgriffith$elm_ui$Internal$Flag$none),
				$mdgriffith$elm_ui$Internal$Style$classes.dX,
				_List_Nil) : _Utils_Tuple3(
				A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$widthFill, $mdgriffith$elm_ui$Internal$Flag$none),
				$mdgriffith$elm_ui$Internal$Style$classes.fF + (' width-fill-' + $elm$core$String$fromInt(portion)),
				_List_fromArray(
					[
						A3(
						$mdgriffith$elm_ui$Internal$Model$Single,
						$mdgriffith$elm_ui$Internal$Style$classes.fV + ('.' + ($mdgriffith$elm_ui$Internal$Style$classes.fh + (' > ' + $mdgriffith$elm_ui$Internal$Style$dot(
							'width-fill-' + $elm$core$String$fromInt(portion))))),
						'flex-grow',
						$elm$core$String$fromInt(portion * 100000))
					]));
		case 3:
			var minSize = w.a;
			var len = w.b;
			var cls = 'min-width-' + $elm$core$String$fromInt(minSize);
			var style = A3(
				$mdgriffith$elm_ui$Internal$Model$Single,
				cls,
				'min-width',
				$elm$core$String$fromInt(minSize) + 'px');
			var _v1 = $mdgriffith$elm_ui$Internal$Model$renderWidth(len);
			var newFlag = _v1.a;
			var newAttrs = _v1.b;
			var newStyle = _v1.c;
			return _Utils_Tuple3(
				A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$widthBetween, newFlag),
				cls + (' ' + newAttrs),
				A2($elm$core$List$cons, style, newStyle));
		default:
			var maxSize = w.a;
			var len = w.b;
			var cls = 'max-width-' + $elm$core$String$fromInt(maxSize);
			var style = A3(
				$mdgriffith$elm_ui$Internal$Model$Single,
				cls,
				'max-width',
				$elm$core$String$fromInt(maxSize) + 'px');
			var _v2 = $mdgriffith$elm_ui$Internal$Model$renderWidth(len);
			var newFlag = _v2.a;
			var newAttrs = _v2.b;
			var newStyle = _v2.c;
			return _Utils_Tuple3(
				A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$widthBetween, newFlag),
				cls + (' ' + newAttrs),
				A2($elm$core$List$cons, style, newStyle));
	}
};
var $mdgriffith$elm_ui$Internal$Flag$borderWidth = $mdgriffith$elm_ui$Internal$Flag$flag(27);
var $mdgriffith$elm_ui$Internal$Model$skippable = F2(
	function (flag, style) {
		if (_Utils_eq(flag, $mdgriffith$elm_ui$Internal$Flag$borderWidth)) {
			if (style.$ === 3) {
				var val = style.c;
				switch (val) {
					case '0px':
						return true;
					case '1px':
						return true;
					case '2px':
						return true;
					case '3px':
						return true;
					case '4px':
						return true;
					case '5px':
						return true;
					case '6px':
						return true;
					default:
						return false;
				}
			} else {
				return false;
			}
		} else {
			switch (style.$) {
				case 2:
					var i = style.a;
					return (i >= 8) && (i <= 32);
				case 7:
					var name = style.a;
					var t = style.b;
					var r = style.c;
					var b = style.d;
					var l = style.e;
					return _Utils_eq(t, b) && (_Utils_eq(t, r) && (_Utils_eq(t, l) && ((t >= 0) && (t <= 24))));
				default:
					return false;
			}
		}
	});
var $mdgriffith$elm_ui$Internal$Flag$width = $mdgriffith$elm_ui$Internal$Flag$flag(6);
var $mdgriffith$elm_ui$Internal$Flag$xAlign = $mdgriffith$elm_ui$Internal$Flag$flag(30);
var $mdgriffith$elm_ui$Internal$Flag$yAlign = $mdgriffith$elm_ui$Internal$Flag$flag(29);
var $mdgriffith$elm_ui$Internal$Model$gatherAttrRecursive = F8(
	function (classes, node, has, transform, styles, attrs, children, elementAttrs) {
		gatherAttrRecursive:
		while (true) {
			if (!elementAttrs.b) {
				var _v1 = $mdgriffith$elm_ui$Internal$Model$transformClass(transform);
				if (_v1.$ === 1) {
					return {
						bY: A2(
							$elm$core$List$cons,
							$elm$html$Html$Attributes$class(classes),
							attrs),
						ga: children,
						aS: has,
						aU: node,
						hJ: styles
					};
				} else {
					var _class = _v1.a;
					return {
						bY: A2(
							$elm$core$List$cons,
							$elm$html$Html$Attributes$class(classes + (' ' + _class)),
							attrs),
						ga: children,
						aS: has,
						aU: node,
						hJ: A2(
							$elm$core$List$cons,
							$mdgriffith$elm_ui$Internal$Model$Transform(transform),
							styles)
					};
				}
			} else {
				var attribute = elementAttrs.a;
				var remaining = elementAttrs.b;
				switch (attribute.$) {
					case 0:
						var $temp$classes = classes,
							$temp$node = node,
							$temp$has = has,
							$temp$transform = transform,
							$temp$styles = styles,
							$temp$attrs = attrs,
							$temp$children = children,
							$temp$elementAttrs = remaining;
						classes = $temp$classes;
						node = $temp$node;
						has = $temp$has;
						transform = $temp$transform;
						styles = $temp$styles;
						attrs = $temp$attrs;
						children = $temp$children;
						elementAttrs = $temp$elementAttrs;
						continue gatherAttrRecursive;
					case 3:
						var flag = attribute.a;
						var exactClassName = attribute.b;
						if (A2($mdgriffith$elm_ui$Internal$Flag$present, flag, has)) {
							var $temp$classes = classes,
								$temp$node = node,
								$temp$has = has,
								$temp$transform = transform,
								$temp$styles = styles,
								$temp$attrs = attrs,
								$temp$children = children,
								$temp$elementAttrs = remaining;
							classes = $temp$classes;
							node = $temp$node;
							has = $temp$has;
							transform = $temp$transform;
							styles = $temp$styles;
							attrs = $temp$attrs;
							children = $temp$children;
							elementAttrs = $temp$elementAttrs;
							continue gatherAttrRecursive;
						} else {
							var $temp$classes = exactClassName + (' ' + classes),
								$temp$node = node,
								$temp$has = A2($mdgriffith$elm_ui$Internal$Flag$add, flag, has),
								$temp$transform = transform,
								$temp$styles = styles,
								$temp$attrs = attrs,
								$temp$children = children,
								$temp$elementAttrs = remaining;
							classes = $temp$classes;
							node = $temp$node;
							has = $temp$has;
							transform = $temp$transform;
							styles = $temp$styles;
							attrs = $temp$attrs;
							children = $temp$children;
							elementAttrs = $temp$elementAttrs;
							continue gatherAttrRecursive;
						}
					case 1:
						var actualAttribute = attribute.a;
						var $temp$classes = classes,
							$temp$node = node,
							$temp$has = has,
							$temp$transform = transform,
							$temp$styles = styles,
							$temp$attrs = A2($elm$core$List$cons, actualAttribute, attrs),
							$temp$children = children,
							$temp$elementAttrs = remaining;
						classes = $temp$classes;
						node = $temp$node;
						has = $temp$has;
						transform = $temp$transform;
						styles = $temp$styles;
						attrs = $temp$attrs;
						children = $temp$children;
						elementAttrs = $temp$elementAttrs;
						continue gatherAttrRecursive;
					case 4:
						var flag = attribute.a;
						var style = attribute.b;
						if (A2($mdgriffith$elm_ui$Internal$Flag$present, flag, has)) {
							var $temp$classes = classes,
								$temp$node = node,
								$temp$has = has,
								$temp$transform = transform,
								$temp$styles = styles,
								$temp$attrs = attrs,
								$temp$children = children,
								$temp$elementAttrs = remaining;
							classes = $temp$classes;
							node = $temp$node;
							has = $temp$has;
							transform = $temp$transform;
							styles = $temp$styles;
							attrs = $temp$attrs;
							children = $temp$children;
							elementAttrs = $temp$elementAttrs;
							continue gatherAttrRecursive;
						} else {
							if (A2($mdgriffith$elm_ui$Internal$Model$skippable, flag, style)) {
								var $temp$classes = $mdgriffith$elm_ui$Internal$Model$getStyleName(style) + (' ' + classes),
									$temp$node = node,
									$temp$has = A2($mdgriffith$elm_ui$Internal$Flag$add, flag, has),
									$temp$transform = transform,
									$temp$styles = styles,
									$temp$attrs = attrs,
									$temp$children = children,
									$temp$elementAttrs = remaining;
								classes = $temp$classes;
								node = $temp$node;
								has = $temp$has;
								transform = $temp$transform;
								styles = $temp$styles;
								attrs = $temp$attrs;
								children = $temp$children;
								elementAttrs = $temp$elementAttrs;
								continue gatherAttrRecursive;
							} else {
								var $temp$classes = $mdgriffith$elm_ui$Internal$Model$getStyleName(style) + (' ' + classes),
									$temp$node = node,
									$temp$has = A2($mdgriffith$elm_ui$Internal$Flag$add, flag, has),
									$temp$transform = transform,
									$temp$styles = A2($elm$core$List$cons, style, styles),
									$temp$attrs = attrs,
									$temp$children = children,
									$temp$elementAttrs = remaining;
								classes = $temp$classes;
								node = $temp$node;
								has = $temp$has;
								transform = $temp$transform;
								styles = $temp$styles;
								attrs = $temp$attrs;
								children = $temp$children;
								elementAttrs = $temp$elementAttrs;
								continue gatherAttrRecursive;
							}
						}
					case 10:
						var flag = attribute.a;
						var component = attribute.b;
						var $temp$classes = classes,
							$temp$node = node,
							$temp$has = A2($mdgriffith$elm_ui$Internal$Flag$add, flag, has),
							$temp$transform = A2($mdgriffith$elm_ui$Internal$Model$composeTransformation, transform, component),
							$temp$styles = styles,
							$temp$attrs = attrs,
							$temp$children = children,
							$temp$elementAttrs = remaining;
						classes = $temp$classes;
						node = $temp$node;
						has = $temp$has;
						transform = $temp$transform;
						styles = $temp$styles;
						attrs = $temp$attrs;
						children = $temp$children;
						elementAttrs = $temp$elementAttrs;
						continue gatherAttrRecursive;
					case 7:
						var width = attribute.a;
						if (A2($mdgriffith$elm_ui$Internal$Flag$present, $mdgriffith$elm_ui$Internal$Flag$width, has)) {
							var $temp$classes = classes,
								$temp$node = node,
								$temp$has = has,
								$temp$transform = transform,
								$temp$styles = styles,
								$temp$attrs = attrs,
								$temp$children = children,
								$temp$elementAttrs = remaining;
							classes = $temp$classes;
							node = $temp$node;
							has = $temp$has;
							transform = $temp$transform;
							styles = $temp$styles;
							attrs = $temp$attrs;
							children = $temp$children;
							elementAttrs = $temp$elementAttrs;
							continue gatherAttrRecursive;
						} else {
							switch (width.$) {
								case 0:
									var px = width.a;
									var $temp$classes = ($mdgriffith$elm_ui$Internal$Style$classes.fE + (' width-px-' + $elm$core$String$fromInt(px))) + (' ' + classes),
										$temp$node = node,
										$temp$has = A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$width, has),
										$temp$transform = transform,
										$temp$styles = A2(
										$elm$core$List$cons,
										A3(
											$mdgriffith$elm_ui$Internal$Model$Single,
											'width-px-' + $elm$core$String$fromInt(px),
											'width',
											$elm$core$String$fromInt(px) + 'px'),
										styles),
										$temp$attrs = attrs,
										$temp$children = children,
										$temp$elementAttrs = remaining;
									classes = $temp$classes;
									node = $temp$node;
									has = $temp$has;
									transform = $temp$transform;
									styles = $temp$styles;
									attrs = $temp$attrs;
									children = $temp$children;
									elementAttrs = $temp$elementAttrs;
									continue gatherAttrRecursive;
								case 1:
									var $temp$classes = classes + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.dW),
										$temp$node = node,
										$temp$has = A2(
										$mdgriffith$elm_ui$Internal$Flag$add,
										$mdgriffith$elm_ui$Internal$Flag$widthContent,
										A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$width, has)),
										$temp$transform = transform,
										$temp$styles = styles,
										$temp$attrs = attrs,
										$temp$children = children,
										$temp$elementAttrs = remaining;
									classes = $temp$classes;
									node = $temp$node;
									has = $temp$has;
									transform = $temp$transform;
									styles = $temp$styles;
									attrs = $temp$attrs;
									children = $temp$children;
									elementAttrs = $temp$elementAttrs;
									continue gatherAttrRecursive;
								case 2:
									var portion = width.a;
									if (portion === 1) {
										var $temp$classes = classes + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.dX),
											$temp$node = node,
											$temp$has = A2(
											$mdgriffith$elm_ui$Internal$Flag$add,
											$mdgriffith$elm_ui$Internal$Flag$widthFill,
											A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$width, has)),
											$temp$transform = transform,
											$temp$styles = styles,
											$temp$attrs = attrs,
											$temp$children = children,
											$temp$elementAttrs = remaining;
										classes = $temp$classes;
										node = $temp$node;
										has = $temp$has;
										transform = $temp$transform;
										styles = $temp$styles;
										attrs = $temp$attrs;
										children = $temp$children;
										elementAttrs = $temp$elementAttrs;
										continue gatherAttrRecursive;
									} else {
										var $temp$classes = classes + (' ' + ($mdgriffith$elm_ui$Internal$Style$classes.fF + (' width-fill-' + $elm$core$String$fromInt(portion)))),
											$temp$node = node,
											$temp$has = A2(
											$mdgriffith$elm_ui$Internal$Flag$add,
											$mdgriffith$elm_ui$Internal$Flag$widthFill,
											A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$width, has)),
											$temp$transform = transform,
											$temp$styles = A2(
											$elm$core$List$cons,
											A3(
												$mdgriffith$elm_ui$Internal$Model$Single,
												$mdgriffith$elm_ui$Internal$Style$classes.fV + ('.' + ($mdgriffith$elm_ui$Internal$Style$classes.fh + (' > ' + $mdgriffith$elm_ui$Internal$Style$dot(
													'width-fill-' + $elm$core$String$fromInt(portion))))),
												'flex-grow',
												$elm$core$String$fromInt(portion * 100000)),
											styles),
											$temp$attrs = attrs,
											$temp$children = children,
											$temp$elementAttrs = remaining;
										classes = $temp$classes;
										node = $temp$node;
										has = $temp$has;
										transform = $temp$transform;
										styles = $temp$styles;
										attrs = $temp$attrs;
										children = $temp$children;
										elementAttrs = $temp$elementAttrs;
										continue gatherAttrRecursive;
									}
								default:
									var _v4 = $mdgriffith$elm_ui$Internal$Model$renderWidth(width);
									var addToFlags = _v4.a;
									var newClass = _v4.b;
									var newStyles = _v4.c;
									var $temp$classes = classes + (' ' + newClass),
										$temp$node = node,
										$temp$has = A2(
										$mdgriffith$elm_ui$Internal$Flag$merge,
										addToFlags,
										A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$width, has)),
										$temp$transform = transform,
										$temp$styles = _Utils_ap(newStyles, styles),
										$temp$attrs = attrs,
										$temp$children = children,
										$temp$elementAttrs = remaining;
									classes = $temp$classes;
									node = $temp$node;
									has = $temp$has;
									transform = $temp$transform;
									styles = $temp$styles;
									attrs = $temp$attrs;
									children = $temp$children;
									elementAttrs = $temp$elementAttrs;
									continue gatherAttrRecursive;
							}
						}
					case 8:
						var height = attribute.a;
						if (A2($mdgriffith$elm_ui$Internal$Flag$present, $mdgriffith$elm_ui$Internal$Flag$height, has)) {
							var $temp$classes = classes,
								$temp$node = node,
								$temp$has = has,
								$temp$transform = transform,
								$temp$styles = styles,
								$temp$attrs = attrs,
								$temp$children = children,
								$temp$elementAttrs = remaining;
							classes = $temp$classes;
							node = $temp$node;
							has = $temp$has;
							transform = $temp$transform;
							styles = $temp$styles;
							attrs = $temp$attrs;
							children = $temp$children;
							elementAttrs = $temp$elementAttrs;
							continue gatherAttrRecursive;
						} else {
							switch (height.$) {
								case 0:
									var px = height.a;
									var val = $elm$core$String$fromInt(px) + 'px';
									var name = 'height-px-' + val;
									var $temp$classes = $mdgriffith$elm_ui$Internal$Style$classes.ev + (' ' + (name + (' ' + classes))),
										$temp$node = node,
										$temp$has = A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$height, has),
										$temp$transform = transform,
										$temp$styles = A2(
										$elm$core$List$cons,
										A3($mdgriffith$elm_ui$Internal$Model$Single, name, 'height ', val),
										styles),
										$temp$attrs = attrs,
										$temp$children = children,
										$temp$elementAttrs = remaining;
									classes = $temp$classes;
									node = $temp$node;
									has = $temp$has;
									transform = $temp$transform;
									styles = $temp$styles;
									attrs = $temp$attrs;
									children = $temp$children;
									elementAttrs = $temp$elementAttrs;
									continue gatherAttrRecursive;
								case 1:
									var $temp$classes = $mdgriffith$elm_ui$Internal$Style$classes.cP + (' ' + classes),
										$temp$node = node,
										$temp$has = A2(
										$mdgriffith$elm_ui$Internal$Flag$add,
										$mdgriffith$elm_ui$Internal$Flag$heightContent,
										A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$height, has)),
										$temp$transform = transform,
										$temp$styles = styles,
										$temp$attrs = attrs,
										$temp$children = children,
										$temp$elementAttrs = remaining;
									classes = $temp$classes;
									node = $temp$node;
									has = $temp$has;
									transform = $temp$transform;
									styles = $temp$styles;
									attrs = $temp$attrs;
									children = $temp$children;
									elementAttrs = $temp$elementAttrs;
									continue gatherAttrRecursive;
								case 2:
									var portion = height.a;
									if (portion === 1) {
										var $temp$classes = $mdgriffith$elm_ui$Internal$Style$classes.cQ + (' ' + classes),
											$temp$node = node,
											$temp$has = A2(
											$mdgriffith$elm_ui$Internal$Flag$add,
											$mdgriffith$elm_ui$Internal$Flag$heightFill,
											A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$height, has)),
											$temp$transform = transform,
											$temp$styles = styles,
											$temp$attrs = attrs,
											$temp$children = children,
											$temp$elementAttrs = remaining;
										classes = $temp$classes;
										node = $temp$node;
										has = $temp$has;
										transform = $temp$transform;
										styles = $temp$styles;
										attrs = $temp$attrs;
										children = $temp$children;
										elementAttrs = $temp$elementAttrs;
										continue gatherAttrRecursive;
									} else {
										var $temp$classes = classes + (' ' + ($mdgriffith$elm_ui$Internal$Style$classes.ew + (' height-fill-' + $elm$core$String$fromInt(portion)))),
											$temp$node = node,
											$temp$has = A2(
											$mdgriffith$elm_ui$Internal$Flag$add,
											$mdgriffith$elm_ui$Internal$Flag$heightFill,
											A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$height, has)),
											$temp$transform = transform,
											$temp$styles = A2(
											$elm$core$List$cons,
											A3(
												$mdgriffith$elm_ui$Internal$Model$Single,
												$mdgriffith$elm_ui$Internal$Style$classes.fV + ('.' + ($mdgriffith$elm_ui$Internal$Style$classes.av + (' > ' + $mdgriffith$elm_ui$Internal$Style$dot(
													'height-fill-' + $elm$core$String$fromInt(portion))))),
												'flex-grow',
												$elm$core$String$fromInt(portion * 100000)),
											styles),
											$temp$attrs = attrs,
											$temp$children = children,
											$temp$elementAttrs = remaining;
										classes = $temp$classes;
										node = $temp$node;
										has = $temp$has;
										transform = $temp$transform;
										styles = $temp$styles;
										attrs = $temp$attrs;
										children = $temp$children;
										elementAttrs = $temp$elementAttrs;
										continue gatherAttrRecursive;
									}
								default:
									var _v6 = $mdgriffith$elm_ui$Internal$Model$renderHeight(height);
									var addToFlags = _v6.a;
									var newClass = _v6.b;
									var newStyles = _v6.c;
									var $temp$classes = classes + (' ' + newClass),
										$temp$node = node,
										$temp$has = A2(
										$mdgriffith$elm_ui$Internal$Flag$merge,
										addToFlags,
										A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$height, has)),
										$temp$transform = transform,
										$temp$styles = _Utils_ap(newStyles, styles),
										$temp$attrs = attrs,
										$temp$children = children,
										$temp$elementAttrs = remaining;
									classes = $temp$classes;
									node = $temp$node;
									has = $temp$has;
									transform = $temp$transform;
									styles = $temp$styles;
									attrs = $temp$attrs;
									children = $temp$children;
									elementAttrs = $temp$elementAttrs;
									continue gatherAttrRecursive;
							}
						}
					case 2:
						var description = attribute.a;
						switch (description.$) {
							case 0:
								var $temp$classes = classes,
									$temp$node = A2($mdgriffith$elm_ui$Internal$Model$addNodeName, 'main', node),
									$temp$has = has,
									$temp$transform = transform,
									$temp$styles = styles,
									$temp$attrs = attrs,
									$temp$children = children,
									$temp$elementAttrs = remaining;
								classes = $temp$classes;
								node = $temp$node;
								has = $temp$has;
								transform = $temp$transform;
								styles = $temp$styles;
								attrs = $temp$attrs;
								children = $temp$children;
								elementAttrs = $temp$elementAttrs;
								continue gatherAttrRecursive;
							case 1:
								var $temp$classes = classes,
									$temp$node = A2($mdgriffith$elm_ui$Internal$Model$addNodeName, 'nav', node),
									$temp$has = has,
									$temp$transform = transform,
									$temp$styles = styles,
									$temp$attrs = attrs,
									$temp$children = children,
									$temp$elementAttrs = remaining;
								classes = $temp$classes;
								node = $temp$node;
								has = $temp$has;
								transform = $temp$transform;
								styles = $temp$styles;
								attrs = $temp$attrs;
								children = $temp$children;
								elementAttrs = $temp$elementAttrs;
								continue gatherAttrRecursive;
							case 2:
								var $temp$classes = classes,
									$temp$node = A2($mdgriffith$elm_ui$Internal$Model$addNodeName, 'footer', node),
									$temp$has = has,
									$temp$transform = transform,
									$temp$styles = styles,
									$temp$attrs = attrs,
									$temp$children = children,
									$temp$elementAttrs = remaining;
								classes = $temp$classes;
								node = $temp$node;
								has = $temp$has;
								transform = $temp$transform;
								styles = $temp$styles;
								attrs = $temp$attrs;
								children = $temp$children;
								elementAttrs = $temp$elementAttrs;
								continue gatherAttrRecursive;
							case 3:
								var $temp$classes = classes,
									$temp$node = A2($mdgriffith$elm_ui$Internal$Model$addNodeName, 'aside', node),
									$temp$has = has,
									$temp$transform = transform,
									$temp$styles = styles,
									$temp$attrs = attrs,
									$temp$children = children,
									$temp$elementAttrs = remaining;
								classes = $temp$classes;
								node = $temp$node;
								has = $temp$has;
								transform = $temp$transform;
								styles = $temp$styles;
								attrs = $temp$attrs;
								children = $temp$children;
								elementAttrs = $temp$elementAttrs;
								continue gatherAttrRecursive;
							case 4:
								var i = description.a;
								if (i <= 1) {
									var $temp$classes = classes,
										$temp$node = A2($mdgriffith$elm_ui$Internal$Model$addNodeName, 'h1', node),
										$temp$has = has,
										$temp$transform = transform,
										$temp$styles = styles,
										$temp$attrs = attrs,
										$temp$children = children,
										$temp$elementAttrs = remaining;
									classes = $temp$classes;
									node = $temp$node;
									has = $temp$has;
									transform = $temp$transform;
									styles = $temp$styles;
									attrs = $temp$attrs;
									children = $temp$children;
									elementAttrs = $temp$elementAttrs;
									continue gatherAttrRecursive;
								} else {
									if (i < 7) {
										var $temp$classes = classes,
											$temp$node = A2(
											$mdgriffith$elm_ui$Internal$Model$addNodeName,
											'h' + $elm$core$String$fromInt(i),
											node),
											$temp$has = has,
											$temp$transform = transform,
											$temp$styles = styles,
											$temp$attrs = attrs,
											$temp$children = children,
											$temp$elementAttrs = remaining;
										classes = $temp$classes;
										node = $temp$node;
										has = $temp$has;
										transform = $temp$transform;
										styles = $temp$styles;
										attrs = $temp$attrs;
										children = $temp$children;
										elementAttrs = $temp$elementAttrs;
										continue gatherAttrRecursive;
									} else {
										var $temp$classes = classes,
											$temp$node = A2($mdgriffith$elm_ui$Internal$Model$addNodeName, 'h6', node),
											$temp$has = has,
											$temp$transform = transform,
											$temp$styles = styles,
											$temp$attrs = attrs,
											$temp$children = children,
											$temp$elementAttrs = remaining;
										classes = $temp$classes;
										node = $temp$node;
										has = $temp$has;
										transform = $temp$transform;
										styles = $temp$styles;
										attrs = $temp$attrs;
										children = $temp$children;
										elementAttrs = $temp$elementAttrs;
										continue gatherAttrRecursive;
									}
								}
							case 9:
								var $temp$classes = classes,
									$temp$node = node,
									$temp$has = has,
									$temp$transform = transform,
									$temp$styles = styles,
									$temp$attrs = attrs,
									$temp$children = children,
									$temp$elementAttrs = remaining;
								classes = $temp$classes;
								node = $temp$node;
								has = $temp$has;
								transform = $temp$transform;
								styles = $temp$styles;
								attrs = $temp$attrs;
								children = $temp$children;
								elementAttrs = $temp$elementAttrs;
								continue gatherAttrRecursive;
							case 8:
								var $temp$classes = classes,
									$temp$node = node,
									$temp$has = has,
									$temp$transform = transform,
									$temp$styles = styles,
									$temp$attrs = A2(
									$elm$core$List$cons,
									A2($elm$virtual_dom$VirtualDom$attribute, 'role', 'button'),
									attrs),
									$temp$children = children,
									$temp$elementAttrs = remaining;
								classes = $temp$classes;
								node = $temp$node;
								has = $temp$has;
								transform = $temp$transform;
								styles = $temp$styles;
								attrs = $temp$attrs;
								children = $temp$children;
								elementAttrs = $temp$elementAttrs;
								continue gatherAttrRecursive;
							case 5:
								var label = description.a;
								var $temp$classes = classes,
									$temp$node = node,
									$temp$has = has,
									$temp$transform = transform,
									$temp$styles = styles,
									$temp$attrs = A2(
									$elm$core$List$cons,
									A2($elm$virtual_dom$VirtualDom$attribute, 'aria-label', label),
									attrs),
									$temp$children = children,
									$temp$elementAttrs = remaining;
								classes = $temp$classes;
								node = $temp$node;
								has = $temp$has;
								transform = $temp$transform;
								styles = $temp$styles;
								attrs = $temp$attrs;
								children = $temp$children;
								elementAttrs = $temp$elementAttrs;
								continue gatherAttrRecursive;
							case 6:
								var $temp$classes = classes,
									$temp$node = node,
									$temp$has = has,
									$temp$transform = transform,
									$temp$styles = styles,
									$temp$attrs = A2(
									$elm$core$List$cons,
									A2($elm$virtual_dom$VirtualDom$attribute, 'aria-live', 'polite'),
									attrs),
									$temp$children = children,
									$temp$elementAttrs = remaining;
								classes = $temp$classes;
								node = $temp$node;
								has = $temp$has;
								transform = $temp$transform;
								styles = $temp$styles;
								attrs = $temp$attrs;
								children = $temp$children;
								elementAttrs = $temp$elementAttrs;
								continue gatherAttrRecursive;
							default:
								var $temp$classes = classes,
									$temp$node = node,
									$temp$has = has,
									$temp$transform = transform,
									$temp$styles = styles,
									$temp$attrs = A2(
									$elm$core$List$cons,
									A2($elm$virtual_dom$VirtualDom$attribute, 'aria-live', 'assertive'),
									attrs),
									$temp$children = children,
									$temp$elementAttrs = remaining;
								classes = $temp$classes;
								node = $temp$node;
								has = $temp$has;
								transform = $temp$transform;
								styles = $temp$styles;
								attrs = $temp$attrs;
								children = $temp$children;
								elementAttrs = $temp$elementAttrs;
								continue gatherAttrRecursive;
						}
					case 9:
						var location = attribute.a;
						var elem = attribute.b;
						var newStyles = function () {
							switch (elem.$) {
								case 3:
									return styles;
								case 2:
									var str = elem.a;
									return styles;
								case 0:
									var html = elem.a;
									return styles;
								default:
									var styled = elem.a;
									return _Utils_ap(styles, styled.hJ);
							}
						}();
						var $temp$classes = classes,
							$temp$node = node,
							$temp$has = has,
							$temp$transform = transform,
							$temp$styles = newStyles,
							$temp$attrs = attrs,
							$temp$children = A3($mdgriffith$elm_ui$Internal$Model$addNearbyElement, location, elem, children),
							$temp$elementAttrs = remaining;
						classes = $temp$classes;
						node = $temp$node;
						has = $temp$has;
						transform = $temp$transform;
						styles = $temp$styles;
						attrs = $temp$attrs;
						children = $temp$children;
						elementAttrs = $temp$elementAttrs;
						continue gatherAttrRecursive;
					case 6:
						var x = attribute.a;
						if (A2($mdgriffith$elm_ui$Internal$Flag$present, $mdgriffith$elm_ui$Internal$Flag$xAlign, has)) {
							var $temp$classes = classes,
								$temp$node = node,
								$temp$has = has,
								$temp$transform = transform,
								$temp$styles = styles,
								$temp$attrs = attrs,
								$temp$children = children,
								$temp$elementAttrs = remaining;
							classes = $temp$classes;
							node = $temp$node;
							has = $temp$has;
							transform = $temp$transform;
							styles = $temp$styles;
							attrs = $temp$attrs;
							children = $temp$children;
							elementAttrs = $temp$elementAttrs;
							continue gatherAttrRecursive;
						} else {
							var $temp$classes = $mdgriffith$elm_ui$Internal$Model$alignXName(x) + (' ' + classes),
								$temp$node = node,
								$temp$has = function (flags) {
								switch (x) {
									case 1:
										return A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$centerX, flags);
									case 2:
										return A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$alignRight, flags);
									default:
										return flags;
								}
							}(
								A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$xAlign, has)),
								$temp$transform = transform,
								$temp$styles = styles,
								$temp$attrs = attrs,
								$temp$children = children,
								$temp$elementAttrs = remaining;
							classes = $temp$classes;
							node = $temp$node;
							has = $temp$has;
							transform = $temp$transform;
							styles = $temp$styles;
							attrs = $temp$attrs;
							children = $temp$children;
							elementAttrs = $temp$elementAttrs;
							continue gatherAttrRecursive;
						}
					default:
						var y = attribute.a;
						if (A2($mdgriffith$elm_ui$Internal$Flag$present, $mdgriffith$elm_ui$Internal$Flag$yAlign, has)) {
							var $temp$classes = classes,
								$temp$node = node,
								$temp$has = has,
								$temp$transform = transform,
								$temp$styles = styles,
								$temp$attrs = attrs,
								$temp$children = children,
								$temp$elementAttrs = remaining;
							classes = $temp$classes;
							node = $temp$node;
							has = $temp$has;
							transform = $temp$transform;
							styles = $temp$styles;
							attrs = $temp$attrs;
							children = $temp$children;
							elementAttrs = $temp$elementAttrs;
							continue gatherAttrRecursive;
						} else {
							var $temp$classes = $mdgriffith$elm_ui$Internal$Model$alignYName(y) + (' ' + classes),
								$temp$node = node,
								$temp$has = function (flags) {
								switch (y) {
									case 1:
										return A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$centerY, flags);
									case 2:
										return A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$alignBottom, flags);
									default:
										return flags;
								}
							}(
								A2($mdgriffith$elm_ui$Internal$Flag$add, $mdgriffith$elm_ui$Internal$Flag$yAlign, has)),
								$temp$transform = transform,
								$temp$styles = styles,
								$temp$attrs = attrs,
								$temp$children = children,
								$temp$elementAttrs = remaining;
							classes = $temp$classes;
							node = $temp$node;
							has = $temp$has;
							transform = $temp$transform;
							styles = $temp$styles;
							attrs = $temp$attrs;
							children = $temp$children;
							elementAttrs = $temp$elementAttrs;
							continue gatherAttrRecursive;
						}
				}
			}
		}
	});
var $mdgriffith$elm_ui$Internal$Model$Untransformed = {$: 0};
var $mdgriffith$elm_ui$Internal$Model$untransformed = $mdgriffith$elm_ui$Internal$Model$Untransformed;
var $mdgriffith$elm_ui$Internal$Model$element = F4(
	function (context, node, attributes, children) {
		return A3(
			$mdgriffith$elm_ui$Internal$Model$createElement,
			context,
			children,
			A8(
				$mdgriffith$elm_ui$Internal$Model$gatherAttrRecursive,
				$mdgriffith$elm_ui$Internal$Model$contextClasses(context),
				node,
				$mdgriffith$elm_ui$Internal$Flag$none,
				$mdgriffith$elm_ui$Internal$Model$untransformed,
				_List_Nil,
				_List_Nil,
				$mdgriffith$elm_ui$Internal$Model$NoNearbyChildren,
				$elm$core$List$reverse(attributes)));
	});
var $mdgriffith$elm_ui$Internal$Model$AllowHover = 1;
var $mdgriffith$elm_ui$Internal$Model$Layout = 0;
var $mdgriffith$elm_ui$Internal$Model$Rgba = F4(
	function (a, b, c, d) {
		return {$: 0, a: a, b: b, c: c, d: d};
	});
var $mdgriffith$elm_ui$Internal$Model$focusDefaultStyle = {
	fZ: $elm$core$Maybe$Nothing,
	f2: $elm$core$Maybe$Nothing,
	hx: $elm$core$Maybe$Just(
		{
			a5: 0,
			a6: A4($mdgriffith$elm_ui$Internal$Model$Rgba, 155 / 255, 203 / 255, 1, 1),
			b: _Utils_Tuple2(0, 0),
			fn: 3
		})
};
var $mdgriffith$elm_ui$Internal$Model$optionsToRecord = function (options) {
	var combine = F2(
		function (opt, record) {
			switch (opt.$) {
				case 0:
					var hoverable = opt.a;
					var _v4 = record.gD;
					if (_v4.$ === 1) {
						return _Utils_update(
							record,
							{
								gD: $elm$core$Maybe$Just(hoverable)
							});
					} else {
						return record;
					}
				case 1:
					var focusStyle = opt.a;
					var _v5 = record.gx;
					if (_v5.$ === 1) {
						return _Utils_update(
							record,
							{
								gx: $elm$core$Maybe$Just(focusStyle)
							});
					} else {
						return record;
					}
				default:
					var renderMode = opt.a;
					var _v6 = record.gY;
					if (_v6.$ === 1) {
						return _Utils_update(
							record,
							{
								gY: $elm$core$Maybe$Just(renderMode)
							});
					} else {
						return record;
					}
			}
		});
	var andFinally = function (record) {
		return {
			gx: function () {
				var _v0 = record.gx;
				if (_v0.$ === 1) {
					return $mdgriffith$elm_ui$Internal$Model$focusDefaultStyle;
				} else {
					var focusable = _v0.a;
					return focusable;
				}
			}(),
			gD: function () {
				var _v1 = record.gD;
				if (_v1.$ === 1) {
					return 1;
				} else {
					var hoverable = _v1.a;
					return hoverable;
				}
			}(),
			gY: function () {
				var _v2 = record.gY;
				if (_v2.$ === 1) {
					return 0;
				} else {
					var actualMode = _v2.a;
					return actualMode;
				}
			}()
		};
	};
	return andFinally(
		A3(
			$elm$core$List$foldr,
			combine,
			{gx: $elm$core$Maybe$Nothing, gD: $elm$core$Maybe$Nothing, gY: $elm$core$Maybe$Nothing},
			options));
};
var $mdgriffith$elm_ui$Internal$Model$toHtml = F2(
	function (mode, el) {
		switch (el.$) {
			case 0:
				var html = el.a;
				return html($mdgriffith$elm_ui$Internal$Model$asEl);
			case 1:
				var styles = el.a.hJ;
				var html = el.a.gE;
				return A2(
					html,
					mode(styles),
					$mdgriffith$elm_ui$Internal$Model$asEl);
			case 2:
				var text = el.a;
				return $mdgriffith$elm_ui$Internal$Model$textElement(text);
			default:
				return $mdgriffith$elm_ui$Internal$Model$textElement('');
		}
	});
var $mdgriffith$elm_ui$Internal$Model$renderRoot = F3(
	function (optionList, attributes, child) {
		var options = $mdgriffith$elm_ui$Internal$Model$optionsToRecord(optionList);
		var embedStyle = function () {
			var _v0 = options.gY;
			if (_v0 === 1) {
				return $mdgriffith$elm_ui$Internal$Model$OnlyDynamic(options);
			} else {
				return $mdgriffith$elm_ui$Internal$Model$StaticRootAndDynamic(options);
			}
		}();
		return A2(
			$mdgriffith$elm_ui$Internal$Model$toHtml,
			embedStyle,
			A4(
				$mdgriffith$elm_ui$Internal$Model$element,
				$mdgriffith$elm_ui$Internal$Model$asEl,
				$mdgriffith$elm_ui$Internal$Model$div,
				attributes,
				$mdgriffith$elm_ui$Internal$Model$Unkeyed(
					_List_fromArray(
						[child]))));
	});
var $mdgriffith$elm_ui$Internal$Model$Colored = F3(
	function (a, b, c) {
		return {$: 4, a: a, b: b, c: c};
	});
var $mdgriffith$elm_ui$Internal$Model$FontFamily = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Model$FontSize = function (a) {
	return {$: 2, a: a};
};
var $mdgriffith$elm_ui$Internal$Model$SansSerif = {$: 1};
var $mdgriffith$elm_ui$Internal$Model$StyleClass = F2(
	function (a, b) {
		return {$: 4, a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Model$Typeface = function (a) {
	return {$: 3, a: a};
};
var $mdgriffith$elm_ui$Internal$Flag$bgColor = $mdgriffith$elm_ui$Internal$Flag$flag(8);
var $mdgriffith$elm_ui$Internal$Flag$fontColor = $mdgriffith$elm_ui$Internal$Flag$flag(14);
var $mdgriffith$elm_ui$Internal$Flag$fontFamily = $mdgriffith$elm_ui$Internal$Flag$flag(5);
var $mdgriffith$elm_ui$Internal$Flag$fontSize = $mdgriffith$elm_ui$Internal$Flag$flag(4);
var $mdgriffith$elm_ui$Internal$Model$formatColorClass = function (_v0) {
	var red = _v0.a;
	var green = _v0.b;
	var blue = _v0.c;
	var alpha = _v0.d;
	return $mdgriffith$elm_ui$Internal$Model$floatClass(red) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(green) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(blue) + ('-' + $mdgriffith$elm_ui$Internal$Model$floatClass(alpha))))));
};
var $elm$core$String$words = _String_words;
var $mdgriffith$elm_ui$Internal$Model$renderFontClassName = F2(
	function (font, current) {
		return _Utils_ap(
			current,
			function () {
				switch (font.$) {
					case 0:
						return 'serif';
					case 1:
						return 'sans-serif';
					case 2:
						return 'monospace';
					case 3:
						var name = font.a;
						return A2(
							$elm$core$String$join,
							'-',
							$elm$core$String$words(
								$elm$core$String$toLower(name)));
					case 4:
						var name = font.a;
						var url = font.b;
						return A2(
							$elm$core$String$join,
							'-',
							$elm$core$String$words(
								$elm$core$String$toLower(name)));
					default:
						var name = font.a.gZ;
						return A2(
							$elm$core$String$join,
							'-',
							$elm$core$String$words(
								$elm$core$String$toLower(name)));
				}
			}());
	});
var $mdgriffith$elm_ui$Internal$Model$rootStyle = function () {
	var families = _List_fromArray(
		[
			$mdgriffith$elm_ui$Internal$Model$Typeface('Open Sans'),
			$mdgriffith$elm_ui$Internal$Model$Typeface('Helvetica'),
			$mdgriffith$elm_ui$Internal$Model$Typeface('Verdana'),
			$mdgriffith$elm_ui$Internal$Model$SansSerif
		]);
	return _List_fromArray(
		[
			A2(
			$mdgriffith$elm_ui$Internal$Model$StyleClass,
			$mdgriffith$elm_ui$Internal$Flag$bgColor,
			A3(
				$mdgriffith$elm_ui$Internal$Model$Colored,
				'bg-' + $mdgriffith$elm_ui$Internal$Model$formatColorClass(
					A4($mdgriffith$elm_ui$Internal$Model$Rgba, 1, 1, 1, 0)),
				'background-color',
				A4($mdgriffith$elm_ui$Internal$Model$Rgba, 1, 1, 1, 0))),
			A2(
			$mdgriffith$elm_ui$Internal$Model$StyleClass,
			$mdgriffith$elm_ui$Internal$Flag$fontColor,
			A3(
				$mdgriffith$elm_ui$Internal$Model$Colored,
				'fc-' + $mdgriffith$elm_ui$Internal$Model$formatColorClass(
					A4($mdgriffith$elm_ui$Internal$Model$Rgba, 0, 0, 0, 1)),
				'color',
				A4($mdgriffith$elm_ui$Internal$Model$Rgba, 0, 0, 0, 1))),
			A2(
			$mdgriffith$elm_ui$Internal$Model$StyleClass,
			$mdgriffith$elm_ui$Internal$Flag$fontSize,
			$mdgriffith$elm_ui$Internal$Model$FontSize(20)),
			A2(
			$mdgriffith$elm_ui$Internal$Model$StyleClass,
			$mdgriffith$elm_ui$Internal$Flag$fontFamily,
			A2(
				$mdgriffith$elm_ui$Internal$Model$FontFamily,
				A3($elm$core$List$foldl, $mdgriffith$elm_ui$Internal$Model$renderFontClassName, 'font-', families),
				families))
		]);
}();
var $mdgriffith$elm_ui$Element$layoutWith = F3(
	function (_v0, attrs, child) {
		var options = _v0.eY;
		return A3(
			$mdgriffith$elm_ui$Internal$Model$renderRoot,
			options,
			A2(
				$elm$core$List$cons,
				$mdgriffith$elm_ui$Internal$Model$htmlClass(
					A2(
						$elm$core$String$join,
						' ',
						_List_fromArray(
							[$mdgriffith$elm_ui$Internal$Style$classes.hl, $mdgriffith$elm_ui$Internal$Style$classes.fV, $mdgriffith$elm_ui$Internal$Style$classes.hy]))),
				_Utils_ap($mdgriffith$elm_ui$Internal$Model$rootStyle, attrs)),
			child);
	});
var $mdgriffith$elm_ui$Element$layout = $mdgriffith$elm_ui$Element$layoutWith(
	{eY: _List_Nil});
var $elm$html$Html$node = $elm$virtual_dom$VirtualDom$node;
var $lattyware$elm_fontawesome$FontAwesome$Styles$css = A3(
	$elm$html$Html$node,
	'style',
	_List_Nil,
	_List_fromArray(
		[
			$elm$html$Html$text('svg:not(:root).svg-inline--fa {  overflow: visible;}.svg-inline--fa {  display: inline-block;  font-size: inherit;  height: 1em;  overflow: visible;  vertical-align: -0.125em;}.svg-inline--fa.fa-lg {  vertical-align: -0.225em;}.svg-inline--fa.fa-w-1 {  width: 0.0625em;}.svg-inline--fa.fa-w-2 {  width: 0.125em;}.svg-inline--fa.fa-w-3 {  width: 0.1875em;}.svg-inline--fa.fa-w-4 {  width: 0.25em;}.svg-inline--fa.fa-w-5 {  width: 0.3125em;}.svg-inline--fa.fa-w-6 {  width: 0.375em;}.svg-inline--fa.fa-w-7 {  width: 0.4375em;}.svg-inline--fa.fa-w-8 {  width: 0.5em;}.svg-inline--fa.fa-w-9 {  width: 0.5625em;}.svg-inline--fa.fa-w-10 {  width: 0.625em;}.svg-inline--fa.fa-w-11 {  width: 0.6875em;}.svg-inline--fa.fa-w-12 {  width: 0.75em;}.svg-inline--fa.fa-w-13 {  width: 0.8125em;}.svg-inline--fa.fa-w-14 {  width: 0.875em;}.svg-inline--fa.fa-w-15 {  width: 0.9375em;}.svg-inline--fa.fa-w-16 {  width: 1em;}.svg-inline--fa.fa-w-17 {  width: 1.0625em;}.svg-inline--fa.fa-w-18 {  width: 1.125em;}.svg-inline--fa.fa-w-19 {  width: 1.1875em;}.svg-inline--fa.fa-w-20 {  width: 1.25em;}.svg-inline--fa.fa-pull-left {  margin-right: 0.3em;  width: auto;}.svg-inline--fa.fa-pull-right {  margin-left: 0.3em;  width: auto;}.svg-inline--fa.fa-border {  height: 1.5em;}.svg-inline--fa.fa-li {  width: 2em;}.svg-inline--fa.fa-fw {  width: 1.25em;}.fa-layers svg.svg-inline--fa {  bottom: 0;  left: 0;  margin: auto;  position: absolute;  right: 0;  top: 0;}.fa-layers {  display: inline-block;  height: 1em;  position: relative;  text-align: center;  vertical-align: -0.125em;  width: 1em;}.fa-layers svg.svg-inline--fa {  -webkit-transform-origin: center center;          transform-origin: center center;}.fa-layers-counter, .fa-layers-text {  display: inline-block;  position: absolute;  text-align: center;}.fa-layers-text {  left: 50%;  top: 50%;  -webkit-transform: translate(-50%, -50%);          transform: translate(-50%, -50%);  -webkit-transform-origin: center center;          transform-origin: center center;}.fa-layers-counter {  background-color: #ff253a;  border-radius: 1em;  -webkit-box-sizing: border-box;          box-sizing: border-box;  color: #fff;  height: 1.5em;  line-height: 1;  max-width: 5em;  min-width: 1.5em;  overflow: hidden;  padding: 0.25em;  right: 0;  text-overflow: ellipsis;  top: 0;  -webkit-transform: scale(0.25);          transform: scale(0.25);  -webkit-transform-origin: top right;          transform-origin: top right;}.fa-layers-bottom-right {  bottom: 0;  right: 0;  top: auto;  -webkit-transform: scale(0.25);          transform: scale(0.25);  -webkit-transform-origin: bottom right;          transform-origin: bottom right;}.fa-layers-bottom-left {  bottom: 0;  left: 0;  right: auto;  top: auto;  -webkit-transform: scale(0.25);          transform: scale(0.25);  -webkit-transform-origin: bottom left;          transform-origin: bottom left;}.fa-layers-top-right {  right: 0;  top: 0;  -webkit-transform: scale(0.25);          transform: scale(0.25);  -webkit-transform-origin: top right;          transform-origin: top right;}.fa-layers-top-left {  left: 0;  right: auto;  top: 0;  -webkit-transform: scale(0.25);          transform: scale(0.25);  -webkit-transform-origin: top left;          transform-origin: top left;}.fa-lg {  font-size: 1.3333333333em;  line-height: 0.75em;  vertical-align: -0.0667em;}.fa-xs {  font-size: 0.75em;}.fa-sm {  font-size: 0.875em;}.fa-1x {  font-size: 1em;}.fa-2x {  font-size: 2em;}.fa-3x {  font-size: 3em;}.fa-4x {  font-size: 4em;}.fa-5x {  font-size: 5em;}.fa-6x {  font-size: 6em;}.fa-7x {  font-size: 7em;}.fa-8x {  font-size: 8em;}.fa-9x {  font-size: 9em;}.fa-10x {  font-size: 10em;}.fa-fw {  text-align: center;  width: 1.25em;}.fa-ul {  list-style-type: none;  margin-left: 2.5em;  padding-left: 0;}.fa-ul > li {  position: relative;}.fa-li {  left: -2em;  position: absolute;  text-align: center;  width: 2em;  line-height: inherit;}.fa-border {  border: solid 0.08em #eee;  border-radius: 0.1em;  padding: 0.2em 0.25em 0.15em;}.fa-pull-left {  float: left;}.fa-pull-right {  float: right;}.fa.fa-pull-left,.fas.fa-pull-left,.far.fa-pull-left,.fal.fa-pull-left,.fab.fa-pull-left {  margin-right: 0.3em;}.fa.fa-pull-right,.fas.fa-pull-right,.far.fa-pull-right,.fal.fa-pull-right,.fab.fa-pull-right {  margin-left: 0.3em;}.fa-spin {  -webkit-animation: fa-spin 2s infinite linear;          animation: fa-spin 2s infinite linear;}.fa-pulse {  -webkit-animation: fa-spin 1s infinite steps(8);          animation: fa-spin 1s infinite steps(8);}@-webkit-keyframes fa-spin {  0% {    -webkit-transform: rotate(0deg);            transform: rotate(0deg);  }  100% {    -webkit-transform: rotate(360deg);            transform: rotate(360deg);  }}@keyframes fa-spin {  0% {    -webkit-transform: rotate(0deg);            transform: rotate(0deg);  }  100% {    -webkit-transform: rotate(360deg);            transform: rotate(360deg);  }}.fa-rotate-90 {  -ms-filter: \"progid:DXImageTransform.Microsoft.BasicImage(rotation=1)\";  -webkit-transform: rotate(90deg);          transform: rotate(90deg);}.fa-rotate-180 {  -ms-filter: \"progid:DXImageTransform.Microsoft.BasicImage(rotation=2)\";  -webkit-transform: rotate(180deg);          transform: rotate(180deg);}.fa-rotate-270 {  -ms-filter: \"progid:DXImageTransform.Microsoft.BasicImage(rotation=3)\";  -webkit-transform: rotate(270deg);          transform: rotate(270deg);}.fa-flip-horizontal {  -ms-filter: \"progid:DXImageTransform.Microsoft.BasicImage(rotation=0, mirror=1)\";  -webkit-transform: scale(-1, 1);          transform: scale(-1, 1);}.fa-flip-vertical {  -ms-filter: \"progid:DXImageTransform.Microsoft.BasicImage(rotation=2, mirror=1)\";  -webkit-transform: scale(1, -1);          transform: scale(1, -1);}.fa-flip-both, .fa-flip-horizontal.fa-flip-vertical {  -ms-filter: \"progid:DXImageTransform.Microsoft.BasicImage(rotation=2, mirror=1)\";  -webkit-transform: scale(-1, -1);          transform: scale(-1, -1);}:root .fa-rotate-90,:root .fa-rotate-180,:root .fa-rotate-270,:root .fa-flip-horizontal,:root .fa-flip-vertical,:root .fa-flip-both {  -webkit-filter: none;          filter: none;}.fa-stack {  display: inline-block;  height: 2em;  position: relative;  width: 2.5em;}.fa-stack-1x,.fa-stack-2x {  bottom: 0;  left: 0;  margin: auto;  position: absolute;  right: 0;  top: 0;}.svg-inline--fa.fa-stack-1x {  height: 1em;  width: 1.25em;}.svg-inline--fa.fa-stack-2x {  height: 2em;  width: 2.5em;}.fa-inverse {  color: #fff;}.sr-only {  border: 0;  clip: rect(0, 0, 0, 0);  height: 1px;  margin: -1px;  overflow: hidden;  padding: 0;  position: absolute;  width: 1px;}.sr-only-focusable:active, .sr-only-focusable:focus {  clip: auto;  height: auto;  margin: 0;  overflow: visible;  position: static;  width: auto;}.svg-inline--fa .fa-primary {  fill: var(--fa-primary-color, currentColor);  opacity: 1;  opacity: var(--fa-primary-opacity, 1);}.svg-inline--fa .fa-secondary {  fill: var(--fa-secondary-color, currentColor);  opacity: 0.4;  opacity: var(--fa-secondary-opacity, 0.4);}.svg-inline--fa.fa-swap-opacity .fa-primary {  opacity: 0.4;  opacity: var(--fa-secondary-opacity, 0.4);}.svg-inline--fa.fa-swap-opacity .fa-secondary {  opacity: 1;  opacity: var(--fa-primary-opacity, 1);}.svg-inline--fa mask .fa-primary,.svg-inline--fa mask .fa-secondary {  fill: black;}.fad.fa-inverse {  color: #fff;}')
		]));
var $mdgriffith$elm_ui$Internal$Model$Fill = function (a) {
	return {$: 2, a: a};
};
var $mdgriffith$elm_ui$Element$fill = $mdgriffith$elm_ui$Internal$Model$Fill(1);
var $mdgriffith$elm_ui$Internal$Model$Height = function (a) {
	return {$: 8, a: a};
};
var $mdgriffith$elm_ui$Element$height = $mdgriffith$elm_ui$Internal$Model$Height;
var $elm$virtual_dom$VirtualDom$style = _VirtualDom_style;
var $elm$html$Html$Attributes$style = $elm$virtual_dom$VirtualDom$style;
var $mdgriffith$elm_ui$Internal$Model$Width = function (a) {
	return {$: 7, a: a};
};
var $mdgriffith$elm_ui$Element$width = $mdgriffith$elm_ui$Internal$Model$Width;
var $author$project$Main$layoutWithFontAwesomeStyles = function (node) {
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				A2($elm$html$Html$Attributes$style, 'height', '100%'),
				A2($elm$html$Html$Attributes$style, 'width', '100%')
			]),
		_List_fromArray(
			[
				$lattyware$elm_fontawesome$FontAwesome$Styles$css,
				A2(
				$mdgriffith$elm_ui$Element$layout,
				_List_fromArray(
					[
						$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
						$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
					]),
				node)
			]));
};
var $mdgriffith$elm_ui$Element$fillPortion = $mdgriffith$elm_ui$Internal$Model$Fill;
var $author$project$Main$biggerElement = $mdgriffith$elm_ui$Element$fillPortion(1618);
var $mdgriffith$elm_ui$Internal$Model$Content = {$: 1};
var $mdgriffith$elm_ui$Element$shrink = $mdgriffith$elm_ui$Internal$Model$Content;
var $mdgriffith$elm_ui$Element$el = F2(
	function (attrs, child) {
		return A4(
			$mdgriffith$elm_ui$Internal$Model$element,
			$mdgriffith$elm_ui$Internal$Model$asEl,
			$mdgriffith$elm_ui$Internal$Model$div,
			A2(
				$elm$core$List$cons,
				$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$shrink),
				A2(
					$elm$core$List$cons,
					$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$shrink),
					attrs)),
			$mdgriffith$elm_ui$Internal$Model$Unkeyed(
				_List_fromArray(
					[child])));
	});
var $author$project$Main$ChangeTab = function (a) {
	return {$: 7, a: a};
};
var $author$project$Main$CreateMode = 1;
var $author$project$Main$DiscoveryMode = 2;
var $author$project$Main$EditMode = 0;
var $author$project$Main$ExportMode = 3;
var $author$project$Main$FileDownload = {$: 6};
var $mdgriffith$elm_ui$Internal$Model$AlignY = function (a) {
	return {$: 5, a: a};
};
var $mdgriffith$elm_ui$Internal$Model$CenterY = 1;
var $mdgriffith$elm_ui$Element$centerY = $mdgriffith$elm_ui$Internal$Model$AlignY(1);
var $author$project$Main$contactUrl = 'https://github.com/varunbhoopalam/slipbox';
var $elm$html$Html$Attributes$href = function (url) {
	return A2(
		$elm$html$Html$Attributes$stringProperty,
		'href',
		_VirtualDom_noJavaScriptUri(url));
};
var $elm$html$Html$Attributes$rel = _VirtualDom_attribute('rel');
var $elm$html$Html$Attributes$target = $elm$html$Html$Attributes$stringProperty('target');
var $mdgriffith$elm_ui$Element$newTabLink = F2(
	function (attrs, _v0) {
		var url = _v0.h9;
		var label = _v0.q;
		return A4(
			$mdgriffith$elm_ui$Internal$Model$element,
			$mdgriffith$elm_ui$Internal$Model$asEl,
			$mdgriffith$elm_ui$Internal$Model$NodeName('a'),
			A2(
				$elm$core$List$cons,
				$mdgriffith$elm_ui$Internal$Model$Attr(
					$elm$html$Html$Attributes$href(url)),
				A2(
					$elm$core$List$cons,
					$mdgriffith$elm_ui$Internal$Model$Attr(
						$elm$html$Html$Attributes$rel('noopener noreferrer')),
					A2(
						$elm$core$List$cons,
						$mdgriffith$elm_ui$Internal$Model$Attr(
							$elm$html$Html$Attributes$target('_blank')),
						A2(
							$elm$core$List$cons,
							$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$shrink),
							A2(
								$elm$core$List$cons,
								$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$shrink),
								A2(
									$elm$core$List$cons,
									$mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.b5 + (' ' + ($mdgriffith$elm_ui$Internal$Style$classes.aw + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.eM)))),
									attrs)))))),
			$mdgriffith$elm_ui$Internal$Model$Unkeyed(
				_List_fromArray(
					[label])));
	});
var $mdgriffith$elm_ui$Internal$Model$Text = function (a) {
	return {$: 2, a: a};
};
var $mdgriffith$elm_ui$Element$text = function (content) {
	return $mdgriffith$elm_ui$Internal$Model$Text(content);
};
var $mdgriffith$elm_ui$Element$Font$underline = $mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.h7);
var $author$project$Main$aboutButton = A2(
	$mdgriffith$elm_ui$Element$newTabLink,
	_List_fromArray(
		[$mdgriffith$elm_ui$Element$centerY]),
	{
		q: A2(
			$mdgriffith$elm_ui$Element$el,
			_List_fromArray(
				[$mdgriffith$elm_ui$Element$Font$underline]),
			$mdgriffith$elm_ui$Element$text('About')),
		h9: $author$project$Main$contactUrl
	});
var $mdgriffith$elm_ui$Internal$Model$Bottom = 2;
var $mdgriffith$elm_ui$Element$alignBottom = $mdgriffith$elm_ui$Internal$Model$AlignY(2);
var $mdgriffith$elm_ui$Internal$Model$AlignX = function (a) {
	return {$: 6, a: a};
};
var $mdgriffith$elm_ui$Internal$Model$Left = 0;
var $mdgriffith$elm_ui$Element$alignLeft = $mdgriffith$elm_ui$Internal$Model$AlignX(0);
var $author$project$Main$ToggleSideNav = {$: 8};
var $lattyware$elm_fontawesome$FontAwesome$Icon$Icon = F5(
	function (prefix, name, width, height, paths) {
		return {cO: height, gZ: name, hc: paths, hg: prefix, aL: width};
	});
var $lattyware$elm_fontawesome$FontAwesome$Solid$bars = A5(
	$lattyware$elm_fontawesome$FontAwesome$Icon$Icon,
	'fas',
	'bars',
	448,
	512,
	_List_fromArray(
		['M16 132h416c8.837 0 16-7.163 16-16V76c0-8.837-7.163-16-16-16H16C7.163 60 0 67.163 0 76v40c0 8.837 7.163 16 16 16zm0 160h416c8.837 0 16-7.163 16-16v-40c0-8.837-7.163-16-16-16H16c-8.837 0-16 7.163-16 16v40c0 8.837 7.163 16 16 16zm0 160h416c8.837 0 16-7.163 16-16v-40c0-8.837-7.163-16-16-16H16c-8.837 0-16 7.163-16 16v40c0 8.837 7.163 16 16 16z']));
var $mdgriffith$elm_ui$Internal$Model$Button = {$: 8};
var $mdgriffith$elm_ui$Internal$Model$Describe = function (a) {
	return {$: 2, a: a};
};
var $elm$json$Json$Encode$bool = _Json_wrap;
var $elm$html$Html$Attributes$boolProperty = F2(
	function (key, bool) {
		return A2(
			_VirtualDom_property,
			key,
			$elm$json$Json$Encode$bool(bool));
	});
var $elm$html$Html$Attributes$disabled = $elm$html$Html$Attributes$boolProperty('disabled');
var $mdgriffith$elm_ui$Element$Input$enter = 'Enter';
var $mdgriffith$elm_ui$Internal$Model$NoAttribute = {$: 0};
var $mdgriffith$elm_ui$Element$Input$hasFocusStyle = function (attr) {
	if (((attr.$ === 4) && (attr.b.$ === 11)) && (!attr.b.a)) {
		var _v1 = attr.b;
		var _v2 = _v1.a;
		return true;
	} else {
		return false;
	}
};
var $mdgriffith$elm_ui$Element$Input$focusDefault = function (attrs) {
	return A2($elm$core$List$any, $mdgriffith$elm_ui$Element$Input$hasFocusStyle, attrs) ? $mdgriffith$elm_ui$Internal$Model$NoAttribute : $mdgriffith$elm_ui$Internal$Model$htmlClass('focusable');
};
var $elm$virtual_dom$VirtualDom$Normal = function (a) {
	return {$: 0, a: a};
};
var $elm$virtual_dom$VirtualDom$on = _VirtualDom_on;
var $elm$html$Html$Events$on = F2(
	function (event, decoder) {
		return A2(
			$elm$virtual_dom$VirtualDom$on,
			event,
			$elm$virtual_dom$VirtualDom$Normal(decoder));
	});
var $elm$html$Html$Events$onClick = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'click',
		$elm$json$Json$Decode$succeed(msg));
};
var $mdgriffith$elm_ui$Element$Events$onClick = A2($elm$core$Basics$composeL, $mdgriffith$elm_ui$Internal$Model$Attr, $elm$html$Html$Events$onClick);
var $elm$json$Json$Decode$andThen = _Json_andThen;
var $elm$json$Json$Decode$fail = _Json_fail;
var $elm$virtual_dom$VirtualDom$MayPreventDefault = function (a) {
	return {$: 2, a: a};
};
var $elm$html$Html$Events$preventDefaultOn = F2(
	function (event, decoder) {
		return A2(
			$elm$virtual_dom$VirtualDom$on,
			event,
			$elm$virtual_dom$VirtualDom$MayPreventDefault(decoder));
	});
var $mdgriffith$elm_ui$Element$Input$onKeyLookup = function (lookup) {
	var decode = function (code) {
		var _v0 = lookup(code);
		if (_v0.$ === 1) {
			return $elm$json$Json$Decode$fail('No key matched');
		} else {
			var msg = _v0.a;
			return $elm$json$Json$Decode$succeed(msg);
		}
	};
	var isKey = A2(
		$elm$json$Json$Decode$andThen,
		decode,
		A2($elm$json$Json$Decode$field, 'key', $elm$json$Json$Decode$string));
	return $mdgriffith$elm_ui$Internal$Model$Attr(
		A2(
			$elm$html$Html$Events$preventDefaultOn,
			'keydown',
			A2(
				$elm$json$Json$Decode$map,
				function (fired) {
					return _Utils_Tuple2(fired, true);
				},
				isKey)));
};
var $mdgriffith$elm_ui$Internal$Model$Class = F2(
	function (a, b) {
		return {$: 3, a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Flag$cursor = $mdgriffith$elm_ui$Internal$Flag$flag(21);
var $mdgriffith$elm_ui$Element$pointer = A2($mdgriffith$elm_ui$Internal$Model$Class, $mdgriffith$elm_ui$Internal$Flag$cursor, $mdgriffith$elm_ui$Internal$Style$classes.gi);
var $mdgriffith$elm_ui$Element$Input$space = ' ';
var $elm$html$Html$Attributes$tabindex = function (n) {
	return A2(
		_VirtualDom_attribute,
		'tabIndex',
		$elm$core$String$fromInt(n));
};
var $mdgriffith$elm_ui$Element$Input$button = F2(
	function (attrs, _v0) {
		var onPress = _v0.v;
		var label = _v0.q;
		return A4(
			$mdgriffith$elm_ui$Internal$Model$element,
			$mdgriffith$elm_ui$Internal$Model$asEl,
			$mdgriffith$elm_ui$Internal$Model$div,
			A2(
				$elm$core$List$cons,
				$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$shrink),
				A2(
					$elm$core$List$cons,
					$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$shrink),
					A2(
						$elm$core$List$cons,
						$mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.b5 + (' ' + ($mdgriffith$elm_ui$Internal$Style$classes.aw + (' ' + ($mdgriffith$elm_ui$Internal$Style$classes.hv + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.eV)))))),
						A2(
							$elm$core$List$cons,
							$mdgriffith$elm_ui$Element$pointer,
							A2(
								$elm$core$List$cons,
								$mdgriffith$elm_ui$Element$Input$focusDefault(attrs),
								A2(
									$elm$core$List$cons,
									$mdgriffith$elm_ui$Internal$Model$Describe($mdgriffith$elm_ui$Internal$Model$Button),
									A2(
										$elm$core$List$cons,
										$mdgriffith$elm_ui$Internal$Model$Attr(
											$elm$html$Html$Attributes$tabindex(0)),
										function () {
											if (onPress.$ === 1) {
												return A2(
													$elm$core$List$cons,
													$mdgriffith$elm_ui$Internal$Model$Attr(
														$elm$html$Html$Attributes$disabled(true)),
													attrs);
											} else {
												var msg = onPress.a;
												return A2(
													$elm$core$List$cons,
													$mdgriffith$elm_ui$Element$Events$onClick(msg),
													A2(
														$elm$core$List$cons,
														$mdgriffith$elm_ui$Element$Input$onKeyLookup(
															function (code) {
																return _Utils_eq(code, $mdgriffith$elm_ui$Element$Input$enter) ? $elm$core$Maybe$Just(msg) : (_Utils_eq(code, $mdgriffith$elm_ui$Element$Input$space) ? $elm$core$Maybe$Just(msg) : $elm$core$Maybe$Nothing);
															}),
														attrs));
											}
										}()))))))),
			$mdgriffith$elm_ui$Internal$Model$Unkeyed(
				_List_fromArray(
					[label])));
	});
var $elm$svg$Svg$Attributes$class = _VirtualDom_attribute('class');
var $lattyware$elm_fontawesome$FontAwesome$Attributes$fa2x = $elm$svg$Svg$Attributes$class('fa-2x');
var $elm$core$Basics$always = F2(
	function (a, _v0) {
		return a;
	});
var $mdgriffith$elm_ui$Internal$Model$unstyled = A2($elm$core$Basics$composeL, $mdgriffith$elm_ui$Internal$Model$Unstyled, $elm$core$Basics$always);
var $mdgriffith$elm_ui$Element$html = $mdgriffith$elm_ui$Internal$Model$unstyled;
var $lattyware$elm_fontawesome$FontAwesome$Icon$Presentation = $elm$core$Basics$identity;
var $lattyware$elm_fontawesome$FontAwesome$Icon$present = function (icon) {
	return {bY: _List_Nil, eA: icon, cT: $elm$core$Maybe$Nothing, bI: $elm$core$Maybe$Nothing, dx: 'img', dO: $elm$core$Maybe$Nothing, cr: _List_Nil};
};
var $lattyware$elm_fontawesome$FontAwesome$Icon$styled = F2(
	function (attributes, _v0) {
		var presentation = _v0;
		return _Utils_update(
			presentation,
			{
				bY: _Utils_ap(presentation.bY, attributes)
			});
	});
var $elm$html$Html$Attributes$attribute = $elm$virtual_dom$VirtualDom$attribute;
var $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$add = F2(
	function (transform, combined) {
		switch (transform.$) {
			case 0:
				var direction = transform.a;
				var amount = function () {
					if (!direction.$) {
						var by = direction.a;
						return by;
					} else {
						var by = direction.a;
						return -by;
					}
				}();
				return _Utils_update(
					combined,
					{fn: combined.fn + amount});
			case 1:
				var direction = transform.a;
				var _v2 = function () {
					switch (direction.$) {
						case 0:
							var by = direction.a;
							return _Utils_Tuple2(0, -by);
						case 1:
							var by = direction.a;
							return _Utils_Tuple2(0, by);
						case 2:
							var by = direction.a;
							return _Utils_Tuple2(-by, 0);
						default:
							var by = direction.a;
							return _Utils_Tuple2(by, 0);
					}
				}();
				var x = _v2.a;
				var y = _v2.b;
				return _Utils_update(
					combined,
					{dZ: combined.dZ + x, d0: combined.d0 + y});
			case 2:
				var rotation = transform.a;
				return _Utils_update(
					combined,
					{hm: combined.hm + rotation});
			default:
				if (!transform.a) {
					var _v4 = transform.a;
					return _Utils_update(
						combined,
						{gv: true});
				} else {
					var _v5 = transform.a;
					return _Utils_update(
						combined,
						{gw: true});
				}
		}
	});
var $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$baseSize = 16;
var $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$meaninglessTransform = {gv: false, gw: false, hm: 0, fn: $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$baseSize, dZ: 0, d0: 0};
var $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$combine = function (transforms) {
	return A3($elm$core$List$foldl, $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$add, $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$meaninglessTransform, transforms);
};
var $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$meaningfulTransform = function (transforms) {
	var combined = $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$combine(transforms);
	return _Utils_eq(combined, $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$meaninglessTransform) ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(combined);
};
var $elm$svg$Svg$trustedNode = _VirtualDom_nodeNS('http://www.w3.org/2000/svg');
var $elm$svg$Svg$svg = $elm$svg$Svg$trustedNode('svg');
var $elm$svg$Svg$Attributes$id = _VirtualDom_attribute('id');
var $elm$svg$Svg$text = $elm$virtual_dom$VirtualDom$text;
var $elm$svg$Svg$title = $elm$svg$Svg$trustedNode('title');
var $lattyware$elm_fontawesome$FontAwesome$Icon$titledContents = F3(
	function (titleId, contents, title) {
		return A2(
			$elm$core$List$cons,
			A2(
				$elm$svg$Svg$title,
				_List_fromArray(
					[
						$elm$svg$Svg$Attributes$id(titleId)
					]),
				_List_fromArray(
					[
						$elm$svg$Svg$text(title)
					])),
			contents);
	});
var $elm$svg$Svg$Attributes$transform = _VirtualDom_attribute('transform');
var $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$transformForSvg = F3(
	function (containerWidth, iconWidth, transform) {
		var path = 'translate(' + ($elm$core$String$fromFloat((iconWidth / 2) * (-1)) + ' -256)');
		var outer = 'translate(' + ($elm$core$String$fromFloat(containerWidth / 2) + ' 256)');
		var innerTranslate = 'translate(' + ($elm$core$String$fromFloat(transform.dZ * 32) + (',' + ($elm$core$String$fromFloat(transform.d0 * 32) + ') ')));
		var innerRotate = 'rotate(' + ($elm$core$String$fromFloat(transform.hm) + ' 0 0)');
		var flipY = transform.gw ? (-1) : 1;
		var scaleY = (transform.fn / $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$baseSize) * flipY;
		var flipX = transform.gv ? (-1) : 1;
		var scaleX = (transform.fn / $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$baseSize) * flipX;
		var innerScale = 'scale(' + ($elm$core$String$fromFloat(scaleX) + (', ' + ($elm$core$String$fromFloat(scaleY) + ') ')));
		return {
			eB: $elm$svg$Svg$Attributes$transform(
				_Utils_ap(
					innerTranslate,
					_Utils_ap(innerScale, innerRotate))),
			bI: $elm$svg$Svg$Attributes$transform(outer),
			e3: $elm$svg$Svg$Attributes$transform(path)
		};
	});
var $elm$svg$Svg$Attributes$viewBox = _VirtualDom_attribute('viewBox');
var $elm$svg$Svg$Attributes$height = _VirtualDom_attribute('height');
var $elm$svg$Svg$Attributes$width = _VirtualDom_attribute('width');
var $elm$svg$Svg$Attributes$x = _VirtualDom_attribute('x');
var $elm$svg$Svg$Attributes$y = _VirtualDom_attribute('y');
var $lattyware$elm_fontawesome$FontAwesome$Icon$allSpace = _List_fromArray(
	[
		$elm$svg$Svg$Attributes$x('0'),
		$elm$svg$Svg$Attributes$y('0'),
		$elm$svg$Svg$Attributes$width('100%'),
		$elm$svg$Svg$Attributes$height('100%')
	]);
var $elm$svg$Svg$clipPath = $elm$svg$Svg$trustedNode('clipPath');
var $elm$svg$Svg$Attributes$clipPath = _VirtualDom_attribute('clip-path');
var $elm$svg$Svg$Attributes$d = _VirtualDom_attribute('d');
var $elm$svg$Svg$Attributes$fill = _VirtualDom_attribute('fill');
var $elm$svg$Svg$path = $elm$svg$Svg$trustedNode('path');
var $lattyware$elm_fontawesome$FontAwesome$Svg$Internal$corePath = F2(
	function (attrs, d) {
		return A2(
			$elm$svg$Svg$path,
			A2(
				$elm$core$List$cons,
				$elm$svg$Svg$Attributes$fill('currentColor'),
				A2(
					$elm$core$List$cons,
					$elm$svg$Svg$Attributes$d(d),
					attrs)),
			_List_Nil);
	});
var $elm$svg$Svg$g = $elm$svg$Svg$trustedNode('g');
var $lattyware$elm_fontawesome$FontAwesome$Svg$Internal$corePaths = F2(
	function (attrs, icon) {
		var _v0 = icon.hc;
		if (!_v0.b) {
			return A2($lattyware$elm_fontawesome$FontAwesome$Svg$Internal$corePath, attrs, '');
		} else {
			if (!_v0.b.b) {
				var only = _v0.a;
				return A2($lattyware$elm_fontawesome$FontAwesome$Svg$Internal$corePath, attrs, only);
			} else {
				var secondary = _v0.a;
				var _v1 = _v0.b;
				var primary = _v1.a;
				return A2(
					$elm$svg$Svg$g,
					_List_fromArray(
						[
							$elm$svg$Svg$Attributes$class('fa-group')
						]),
					_List_fromArray(
						[
							A2(
							$lattyware$elm_fontawesome$FontAwesome$Svg$Internal$corePath,
							A2(
								$elm$core$List$cons,
								$elm$svg$Svg$Attributes$class('fa-secondary'),
								attrs),
							secondary),
							A2(
							$lattyware$elm_fontawesome$FontAwesome$Svg$Internal$corePath,
							A2(
								$elm$core$List$cons,
								$elm$svg$Svg$Attributes$class('fa-primary'),
								attrs),
							primary)
						]));
			}
		}
	});
var $elm$svg$Svg$defs = $elm$svg$Svg$trustedNode('defs');
var $elm$svg$Svg$mask = $elm$svg$Svg$trustedNode('mask');
var $elm$svg$Svg$Attributes$mask = _VirtualDom_attribute('mask');
var $elm$svg$Svg$Attributes$maskContentUnits = _VirtualDom_attribute('maskContentUnits');
var $elm$svg$Svg$Attributes$maskUnits = _VirtualDom_attribute('maskUnits');
var $elm$svg$Svg$rect = $elm$svg$Svg$trustedNode('rect');
var $lattyware$elm_fontawesome$FontAwesome$Icon$viewMaskedWithTransform = F4(
	function (id, transforms, inner, outer) {
		var maskInnerGroup = A2(
			$elm$svg$Svg$g,
			_List_fromArray(
				[transforms.eB]),
			_List_fromArray(
				[
					A2(
					$lattyware$elm_fontawesome$FontAwesome$Svg$Internal$corePaths,
					_List_fromArray(
						[
							$elm$svg$Svg$Attributes$fill('black'),
							transforms.e3
						]),
					inner)
				]));
		var maskId = 'mask-' + (inner.gZ + ('-' + id));
		var maskTag = A2(
			$elm$svg$Svg$mask,
			_Utils_ap(
				_List_fromArray(
					[
						$elm$svg$Svg$Attributes$id(maskId),
						$elm$svg$Svg$Attributes$maskUnits('userSpaceOnUse'),
						$elm$svg$Svg$Attributes$maskContentUnits('userSpaceOnUse')
					]),
				$lattyware$elm_fontawesome$FontAwesome$Icon$allSpace),
			_List_fromArray(
				[
					A2(
					$elm$svg$Svg$rect,
					A2(
						$elm$core$List$cons,
						$elm$svg$Svg$Attributes$fill('white'),
						$lattyware$elm_fontawesome$FontAwesome$Icon$allSpace),
					_List_Nil),
					A2(
					$elm$svg$Svg$g,
					_List_fromArray(
						[transforms.bI]),
					_List_fromArray(
						[maskInnerGroup]))
				]));
		var clipId = 'clip-' + (outer.gZ + ('-' + id));
		var defs = A2(
			$elm$svg$Svg$defs,
			_List_Nil,
			_List_fromArray(
				[
					A2(
					$elm$svg$Svg$clipPath,
					_List_fromArray(
						[
							$elm$svg$Svg$Attributes$id(clipId)
						]),
					_List_fromArray(
						[
							A2($lattyware$elm_fontawesome$FontAwesome$Svg$Internal$corePaths, _List_Nil, outer)
						])),
					maskTag
				]));
		return _List_fromArray(
			[
				defs,
				A2(
				$elm$svg$Svg$rect,
				$elm$core$List$concat(
					_List_fromArray(
						[
							_List_fromArray(
							[
								$elm$svg$Svg$Attributes$fill('currentColor'),
								$elm$svg$Svg$Attributes$clipPath('url(#' + (clipId + ')')),
								$elm$svg$Svg$Attributes$mask('url(#' + (maskId + ')'))
							]),
							$lattyware$elm_fontawesome$FontAwesome$Icon$allSpace
						])),
				_List_Nil)
			]);
	});
var $lattyware$elm_fontawesome$FontAwesome$Icon$viewWithTransform = F2(
	function (transforms, icon) {
		if (!transforms.$) {
			var ts = transforms.a;
			return A2(
				$elm$svg$Svg$g,
				_List_fromArray(
					[ts.bI]),
				_List_fromArray(
					[
						A2(
						$elm$svg$Svg$g,
						_List_fromArray(
							[ts.eB]),
						_List_fromArray(
							[
								A2(
								$lattyware$elm_fontawesome$FontAwesome$Svg$Internal$corePaths,
								_List_fromArray(
									[ts.e3]),
								icon)
							]))
					]));
		} else {
			return A2($lattyware$elm_fontawesome$FontAwesome$Svg$Internal$corePaths, _List_Nil, icon);
		}
	});
var $lattyware$elm_fontawesome$FontAwesome$Icon$internalView = function (_v0) {
	var icon = _v0.eA;
	var attributes = _v0.bY;
	var transforms = _v0.cr;
	var role = _v0.dx;
	var id = _v0.cT;
	var title = _v0.dO;
	var outer = _v0.bI;
	var alwaysId = A2($elm$core$Maybe$withDefault, icon.gZ, id);
	var titleId = alwaysId + '-title';
	var semantics = A2(
		$elm$core$Maybe$withDefault,
		A2($elm$html$Html$Attributes$attribute, 'aria-hidden', 'true'),
		A2(
			$elm$core$Maybe$map,
			$elm$core$Basics$always(
				A2($elm$html$Html$Attributes$attribute, 'aria-labelledby', titleId)),
			title));
	var _v1 = A2(
		$elm$core$Maybe$withDefault,
		_Utils_Tuple2(icon.aL, icon.cO),
		A2(
			$elm$core$Maybe$map,
			function (o) {
				return _Utils_Tuple2(o.aL, o.cO);
			},
			outer));
	var width = _v1.a;
	var height = _v1.b;
	var classes = _List_fromArray(
		[
			'svg-inline--fa',
			'fa-' + icon.gZ,
			'fa-w-' + $elm$core$String$fromInt(
			$elm$core$Basics$ceiling((width / height) * 16))
		]);
	var svgTransform = A2(
		$elm$core$Maybe$map,
		A2($lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$transformForSvg, width, icon.aL),
		$lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$meaningfulTransform(transforms));
	var contents = function () {
		var resolvedSvgTransform = A2(
			$elm$core$Maybe$withDefault,
			A3($lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$transformForSvg, width, icon.aL, $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$meaninglessTransform),
			svgTransform);
		return A2(
			$elm$core$Maybe$withDefault,
			_List_fromArray(
				[
					A2($lattyware$elm_fontawesome$FontAwesome$Icon$viewWithTransform, svgTransform, icon)
				]),
			A2(
				$elm$core$Maybe$map,
				A3($lattyware$elm_fontawesome$FontAwesome$Icon$viewMaskedWithTransform, alwaysId, resolvedSvgTransform, icon),
				outer));
	}();
	var potentiallyTitledContents = A2(
		$elm$core$Maybe$withDefault,
		contents,
		A2(
			$elm$core$Maybe$map,
			A2($lattyware$elm_fontawesome$FontAwesome$Icon$titledContents, titleId, contents),
			title));
	return A2(
		$elm$svg$Svg$svg,
		$elm$core$List$concat(
			_List_fromArray(
				[
					_List_fromArray(
					[
						A2($elm$html$Html$Attributes$attribute, 'role', role),
						A2($elm$html$Html$Attributes$attribute, 'xmlns', 'http://www.w3.org/2000/svg'),
						$elm$svg$Svg$Attributes$viewBox(
						'0 0 ' + ($elm$core$String$fromInt(width) + (' ' + $elm$core$String$fromInt(height)))),
						semantics
					]),
					A2($elm$core$List$map, $elm$svg$Svg$Attributes$class, classes),
					attributes
				])),
		potentiallyTitledContents);
};
var $lattyware$elm_fontawesome$FontAwesome$Icon$view = function (presentation) {
	return $lattyware$elm_fontawesome$FontAwesome$Icon$internalView(presentation);
};
var $lattyware$elm_fontawesome$FontAwesome$Icon$viewStyled = function (styles) {
	return A2(
		$elm$core$Basics$composeR,
		$lattyware$elm_fontawesome$FontAwesome$Icon$present,
		A2(
			$elm$core$Basics$composeR,
			$lattyware$elm_fontawesome$FontAwesome$Icon$styled(styles),
			$lattyware$elm_fontawesome$FontAwesome$Icon$view));
};
var $author$project$Main$barsButton = A2(
	$mdgriffith$elm_ui$Element$Input$button,
	_List_Nil,
	{
		q: A2(
			$mdgriffith$elm_ui$Element$el,
			_List_Nil,
			$mdgriffith$elm_ui$Element$html(
				A2(
					$lattyware$elm_fontawesome$FontAwesome$Icon$viewStyled,
					_List_fromArray(
						[$lattyware$elm_fontawesome$FontAwesome$Attributes$fa2x]),
					$lattyware$elm_fontawesome$FontAwesome$Solid$bars))),
		v: $elm$core$Maybe$Just($author$project$Main$ToggleSideNav)
	});
var $lattyware$elm_fontawesome$FontAwesome$Solid$brain = A5(
	$lattyware$elm_fontawesome$FontAwesome$Icon$Icon,
	'fas',
	'brain',
	576,
	512,
	_List_fromArray(
		['M208 0c-29.9 0-54.7 20.5-61.8 48.2-.8 0-1.4-.2-2.2-.2-35.3 0-64 28.7-64 64 0 4.8.6 9.5 1.7 14C52.5 138 32 166.6 32 200c0 12.6 3.2 24.3 8.3 34.9C16.3 248.7 0 274.3 0 304c0 33.3 20.4 61.9 49.4 73.9-.9 4.6-1.4 9.3-1.4 14.1 0 39.8 32.2 72 72 72 4.1 0 8.1-.5 12-1.2 9.6 28.5 36.2 49.2 68 49.2 39.8 0 72-32.2 72-72V64c0-35.3-28.7-64-64-64zm368 304c0-29.7-16.3-55.3-40.3-69.1 5.2-10.6 8.3-22.3 8.3-34.9 0-33.4-20.5-62-49.7-74 1-4.5 1.7-9.2 1.7-14 0-35.3-28.7-64-64-64-.8 0-1.5.2-2.2.2C422.7 20.5 397.9 0 368 0c-35.3 0-64 28.6-64 64v376c0 39.8 32.2 72 72 72 31.8 0 58.4-20.7 68-49.2 3.9.7 7.9 1.2 12 1.2 39.8 0 72-32.2 72-72 0-4.8-.5-9.5-1.4-14.1 29-12 49.4-40.6 49.4-73.9z']));
var $lattyware$elm_fontawesome$FontAwesome$Attributes$fw = $elm$svg$Svg$Attributes$class('fa-fw');
var $author$project$Main$iconBuilder = function (icon) {
	return A2(
		$mdgriffith$elm_ui$Element$el,
		_List_Nil,
		$mdgriffith$elm_ui$Element$html(
			A2(
				$lattyware$elm_fontawesome$FontAwesome$Icon$viewStyled,
				_List_fromArray(
					[$lattyware$elm_fontawesome$FontAwesome$Attributes$fa2x, $lattyware$elm_fontawesome$FontAwesome$Attributes$fw]),
				icon)));
};
var $author$project$Main$brainIcon = $author$project$Main$iconBuilder($lattyware$elm_fontawesome$FontAwesome$Solid$brain);
var $mdgriffith$elm_ui$Internal$Model$AsColumn = 1;
var $mdgriffith$elm_ui$Internal$Model$asColumn = 1;
var $mdgriffith$elm_ui$Element$column = F2(
	function (attrs, children) {
		return A4(
			$mdgriffith$elm_ui$Internal$Model$element,
			$mdgriffith$elm_ui$Internal$Model$asColumn,
			$mdgriffith$elm_ui$Internal$Model$div,
			A2(
				$elm$core$List$cons,
				$mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.gg + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.bv)),
				A2(
					$elm$core$List$cons,
					$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$shrink),
					A2(
						$elm$core$List$cons,
						$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$shrink),
						attrs))),
			$mdgriffith$elm_ui$Internal$Model$Unkeyed(children));
	});
var $lattyware$elm_fontawesome$FontAwesome$Solid$fileDownload = A5(
	$lattyware$elm_fontawesome$FontAwesome$Icon$Icon,
	'fas',
	'file-download',
	384,
	512,
	_List_fromArray(
		['M224 136V0H24C10.7 0 0 10.7 0 24v464c0 13.3 10.7 24 24 24h336c13.3 0 24-10.7 24-24V160H248c-13.2 0-24-10.8-24-24zm76.45 211.36l-96.42 95.7c-6.65 6.61-17.39 6.61-24.04 0l-96.42-95.7C73.42 337.29 80.54 320 94.82 320H160v-80c0-8.84 7.16-16 16-16h32c8.84 0 16 7.16 16 16v80h65.18c14.28 0 21.4 17.29 11.27 27.36zM377 105L279.1 7c-4.5-4.5-10.6-7-17-7H256v128h128v-6.1c0-6.3-2.5-12.4-7-16.9z']));
var $author$project$Main$exportIcon = $author$project$Main$iconBuilder($lattyware$elm_fontawesome$FontAwesome$Solid$fileDownload);
var $mdgriffith$elm_ui$Element$Background$color = function (clr) {
	return A2(
		$mdgriffith$elm_ui$Internal$Model$StyleClass,
		$mdgriffith$elm_ui$Internal$Flag$bgColor,
		A3(
			$mdgriffith$elm_ui$Internal$Model$Colored,
			'bg-' + $mdgriffith$elm_ui$Internal$Model$formatColorClass(clr),
			'background-color',
			clr));
};
var $mdgriffith$elm_ui$Element$rgba255 = F4(
	function (red, green, blue, a) {
		return A4($mdgriffith$elm_ui$Internal$Model$Rgba, red / 255, green / 255, blue / 255, a);
	});
var $author$project$Color$heliotropeGray = A3($mdgriffith$elm_ui$Element$rgba255, 187, 172, 193);
var $author$project$Color$heliotropeGrayRegular = $author$project$Color$heliotropeGray(1.0);
var $author$project$Main$leftNavContractedButtonLambda = F4(
	function (alignment, msg, icon, shouldHaveBackground) {
		var buttonAttributes = shouldHaveBackground ? _List_fromArray(
			[
				$mdgriffith$elm_ui$Element$Background$color($author$project$Color$heliotropeGrayRegular)
			]) : _List_Nil;
		return A2(
			$mdgriffith$elm_ui$Element$el,
			_List_fromArray(
				[alignment]),
			A2(
				$mdgriffith$elm_ui$Element$Input$button,
				buttonAttributes,
				{
					q: icon,
					v: $elm$core$Maybe$Just(msg)
				}));
	});
var $mdgriffith$elm_ui$Internal$Model$PaddingStyle = F5(
	function (a, b, c, d, e) {
		return {$: 7, a: a, b: b, c: c, d: d, e: e};
	});
var $mdgriffith$elm_ui$Internal$Flag$padding = $mdgriffith$elm_ui$Internal$Flag$flag(2);
var $mdgriffith$elm_ui$Element$padding = function (x) {
	var f = x;
	return A2(
		$mdgriffith$elm_ui$Internal$Model$StyleClass,
		$mdgriffith$elm_ui$Internal$Flag$padding,
		A5(
			$mdgriffith$elm_ui$Internal$Model$PaddingStyle,
			'p-' + $elm$core$String$fromInt(x),
			f,
			f,
			f,
			f));
};
var $mdgriffith$elm_ui$Internal$Flag$borderRound = $mdgriffith$elm_ui$Internal$Flag$flag(17);
var $mdgriffith$elm_ui$Element$Border$rounded = function (radius) {
	return A2(
		$mdgriffith$elm_ui$Internal$Model$StyleClass,
		$mdgriffith$elm_ui$Internal$Flag$borderRound,
		A3(
			$mdgriffith$elm_ui$Internal$Model$Single,
			'br-' + $elm$core$String$fromInt(radius),
			'border-radius',
			$elm$core$String$fromInt(radius) + 'px'));
};
var $mdgriffith$elm_ui$Internal$Model$AsRow = 0;
var $mdgriffith$elm_ui$Internal$Model$asRow = 0;
var $mdgriffith$elm_ui$Element$row = F2(
	function (attrs, children) {
		return A4(
			$mdgriffith$elm_ui$Internal$Model$element,
			$mdgriffith$elm_ui$Internal$Model$asRow,
			$mdgriffith$elm_ui$Internal$Model$div,
			A2(
				$elm$core$List$cons,
				$mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.bv + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.aw)),
				A2(
					$elm$core$List$cons,
					$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$shrink),
					A2(
						$elm$core$List$cons,
						$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$shrink),
						attrs))),
			$mdgriffith$elm_ui$Internal$Model$Unkeyed(children));
	});
var $mdgriffith$elm_ui$Internal$Model$SpacingStyle = F3(
	function (a, b, c) {
		return {$: 5, a: a, b: b, c: c};
	});
var $mdgriffith$elm_ui$Internal$Flag$spacing = $mdgriffith$elm_ui$Internal$Flag$flag(3);
var $mdgriffith$elm_ui$Internal$Model$spacingName = F2(
	function (x, y) {
		return 'spacing-' + ($elm$core$String$fromInt(x) + ('-' + $elm$core$String$fromInt(y)));
	});
var $mdgriffith$elm_ui$Element$spacingXY = F2(
	function (x, y) {
		return A2(
			$mdgriffith$elm_ui$Internal$Model$StyleClass,
			$mdgriffith$elm_ui$Internal$Flag$spacing,
			A3(
				$mdgriffith$elm_ui$Internal$Model$SpacingStyle,
				A2($mdgriffith$elm_ui$Internal$Model$spacingName, x, y),
				x,
				y));
	});
var $author$project$Main$leftNavExpandedButtonLambda = F5(
	function (alignment, icon, text, msg, shouldHaveBackground) {
		var buttonAttributes = _List_fromArray(
			[
				$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
				$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
				$mdgriffith$elm_ui$Element$Border$rounded(10),
				$mdgriffith$elm_ui$Element$padding(1)
			]);
		var buttonAttributesMaybeWithBackground = shouldHaveBackground ? A2(
			$elm$core$List$cons,
			$mdgriffith$elm_ui$Element$Background$color($author$project$Color$heliotropeGrayRegular),
			buttonAttributes) : buttonAttributes;
		return A2(
			$mdgriffith$elm_ui$Element$el,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
					alignment
				]),
			A2(
				$mdgriffith$elm_ui$Element$Input$button,
				buttonAttributesMaybeWithBackground,
				{
					q: A2(
						$mdgriffith$elm_ui$Element$row,
						_List_fromArray(
							[
								A2($mdgriffith$elm_ui$Element$spacingXY, 16, 0)
							]),
						_List_fromArray(
							[
								icon,
								$mdgriffith$elm_ui$Element$text(text)
							])),
					v: $elm$core$Maybe$Just(msg)
				}));
	});
var $mdgriffith$elm_ui$Internal$Model$MoveY = function (a) {
	return {$: 1, a: a};
};
var $mdgriffith$elm_ui$Internal$Model$TransformComponent = F2(
	function (a, b) {
		return {$: 10, a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Flag$moveY = $mdgriffith$elm_ui$Internal$Flag$flag(26);
var $mdgriffith$elm_ui$Element$moveDown = function (y) {
	return A2(
		$mdgriffith$elm_ui$Internal$Model$TransformComponent,
		$mdgriffith$elm_ui$Internal$Flag$moveY,
		$mdgriffith$elm_ui$Internal$Model$MoveY(y));
};
var $mdgriffith$elm_ui$Internal$Model$MoveX = function (a) {
	return {$: 0, a: a};
};
var $mdgriffith$elm_ui$Internal$Flag$moveX = $mdgriffith$elm_ui$Internal$Flag$flag(25);
var $mdgriffith$elm_ui$Element$moveRight = function (x) {
	return A2(
		$mdgriffith$elm_ui$Internal$Model$TransformComponent,
		$mdgriffith$elm_ui$Internal$Flag$moveX,
		$mdgriffith$elm_ui$Internal$Model$MoveX(x));
};
var $mdgriffith$elm_ui$Internal$Model$Empty = {$: 3};
var $mdgriffith$elm_ui$Element$none = $mdgriffith$elm_ui$Internal$Model$Empty;
var $mdgriffith$elm_ui$Internal$Model$OnRight = 2;
var $mdgriffith$elm_ui$Internal$Model$Nearby = F2(
	function (a, b) {
		return {$: 9, a: a, b: b};
	});
var $mdgriffith$elm_ui$Element$createNearby = F2(
	function (loc, element) {
		if (element.$ === 3) {
			return $mdgriffith$elm_ui$Internal$Model$NoAttribute;
		} else {
			return A2($mdgriffith$elm_ui$Internal$Model$Nearby, loc, element);
		}
	});
var $mdgriffith$elm_ui$Element$onRight = function (element) {
	return A2($mdgriffith$elm_ui$Element$createNearby, 2, element);
};
var $lattyware$elm_fontawesome$FontAwesome$Solid$plus = A5(
	$lattyware$elm_fontawesome$FontAwesome$Icon$Icon,
	'fas',
	'plus',
	448,
	512,
	_List_fromArray(
		['M416 208H272V64c0-17.67-14.33-32-32-32h-32c-17.67 0-32 14.33-32 32v144H32c-17.67 0-32 14.33-32 32v32c0 17.67 14.33 32 32 32h144v144c0 17.67 14.33 32 32 32h32c17.67 0 32-14.33 32-32V304h144c17.67 0 32-14.33 32-32v-32c0-17.67-14.33-32-32-32z']));
var $author$project$Main$plusIcon = $author$project$Main$iconBuilder($lattyware$elm_fontawesome$FontAwesome$Solid$plus);
var $mdgriffith$elm_ui$Internal$Model$Px = function (a) {
	return {$: 0, a: a};
};
var $mdgriffith$elm_ui$Element$px = $mdgriffith$elm_ui$Internal$Model$Px;
var $author$project$Main$sameTab = F2(
	function (tab, tab_) {
		switch (tab.$) {
			case 0:
				if (!tab_) {
					return true;
				} else {
					return false;
				}
			case 1:
				if (tab_ === 1) {
					return true;
				} else {
					return false;
				}
			case 2:
				if (tab_ === 2) {
					return true;
				} else {
					return false;
				}
			default:
				if (tab_ === 3) {
					return true;
				} else {
					return false;
				}
		}
	});
var $lattyware$elm_fontawesome$FontAwesome$Solid$save = A5(
	$lattyware$elm_fontawesome$FontAwesome$Icon$Icon,
	'fas',
	'save',
	448,
	512,
	_List_fromArray(
		['M433.941 129.941l-83.882-83.882A48 48 0 0 0 316.118 32H48C21.49 32 0 53.49 0 80v352c0 26.51 21.49 48 48 48h352c26.51 0 48-21.49 48-48V163.882a48 48 0 0 0-14.059-33.941zM224 416c-35.346 0-64-28.654-64-64 0-35.346 28.654-64 64-64s64 28.654 64 64c0 35.346-28.654 64-64 64zm96-304.52V212c0 6.627-5.373 12-12 12H76c-6.627 0-12-5.373-12-12V108c0-6.627 5.373-12 12-12h228.52c3.183 0 6.235 1.264 8.485 3.515l3.48 3.48A11.996 11.996 0 0 1 320 111.48z']));
var $author$project$Main$saveIcon = $author$project$Main$iconBuilder($lattyware$elm_fontawesome$FontAwesome$Solid$save);
var $mdgriffith$elm_ui$Element$Font$size = function (i) {
	return A2(
		$mdgriffith$elm_ui$Internal$Model$StyleClass,
		$mdgriffith$elm_ui$Internal$Flag$fontSize,
		$mdgriffith$elm_ui$Internal$Model$FontSize(i));
};
var $author$project$Main$smallerElement = $mdgriffith$elm_ui$Element$fillPortion(1000);
var $lattyware$elm_fontawesome$FontAwesome$Solid$tools = A5(
	$lattyware$elm_fontawesome$FontAwesome$Icon$Icon,
	'fas',
	'tools',
	512,
	512,
	_List_fromArray(
		['M501.1 395.7L384 278.6c-23.1-23.1-57.6-27.6-85.4-13.9L192 158.1V96L64 0 0 64l96 128h62.1l106.6 106.6c-13.6 27.8-9.2 62.3 13.9 85.4l117.1 117.1c14.6 14.6 38.2 14.6 52.7 0l52.7-52.7c14.5-14.6 14.5-38.2 0-52.7zM331.7 225c28.3 0 54.9 11 74.9 31l19.4 19.4c15.8-6.9 30.8-16.5 43.8-29.5 37.1-37.1 49.7-89.3 37.9-136.7-2.2-9-13.5-12.1-20.1-5.5l-74.4 74.4-67.9-11.3L334 98.9l74.4-74.4c6.6-6.6 3.4-17.9-5.7-20.2-47.4-11.7-99.6.9-136.6 37.9-28.5 28.5-41.9 66.1-41.2 103.6l82.1 82.1c8.1-1.9 16.5-2.9 24.7-2.9zm-103.9 82l-56.7-56.7L18.7 402.8c-25 25-25 65.5 0 90.5s65.5 25 90.5 0l123.6-123.6c-7.6-19.9-9.9-41.6-5-62.7zM64 472c-13.2 0-24-10.8-24-24 0-13.3 10.7-24 24-24s24 10.7 24 24c0 13.2-10.7 24-24 24z']));
var $author$project$Main$toolsIcon = $author$project$Main$iconBuilder($lattyware$elm_fontawesome$FontAwesome$Solid$tools);
var $author$project$Slipbox$unsavedChanges = function (slipbox) {
	var content = slipbox;
	return content.aJ;
};
var $author$project$Main$versionString = '0.1';
var $author$project$Main$leftNav = F3(
	function (sideNavState, selectedTab, slipbox) {
		var unsavedChangesNode = $author$project$Slipbox$unsavedChanges(slipbox) ? A2(
			$mdgriffith$elm_ui$Element$el,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$Font$size(12),
					$mdgriffith$elm_ui$Element$moveRight(6.0),
					$mdgriffith$elm_ui$Element$moveDown(14.0)
				]),
			$mdgriffith$elm_ui$Element$text('unsaved changes')) : $mdgriffith$elm_ui$Element$none;
		var iconWidth = $mdgriffith$elm_ui$Element$width(
			$mdgriffith$elm_ui$Element$px(35));
		var iconHeight = $mdgriffith$elm_ui$Element$width(
			$mdgriffith$elm_ui$Element$px(40));
		var emptyIcon = A2(
			$mdgriffith$elm_ui$Element$el,
			_List_fromArray(
				[iconWidth, iconHeight]),
			$mdgriffith$elm_ui$Element$none);
		if (!sideNavState) {
			return A2(
				$mdgriffith$elm_ui$Element$column,
				_List_fromArray(
					[
						$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
						$mdgriffith$elm_ui$Element$width(
						$mdgriffith$elm_ui$Element$px(250)),
						$mdgriffith$elm_ui$Element$padding(8),
						A2($mdgriffith$elm_ui$Element$spacingXY, 0, 8)
					]),
				_List_fromArray(
					[
						A2(
						$mdgriffith$elm_ui$Element$column,
						_List_fromArray(
							[
								$mdgriffith$elm_ui$Element$height($author$project$Main$smallerElement),
								$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
								A2($mdgriffith$elm_ui$Element$spacingXY, 0, 8)
							]),
						_List_fromArray(
							[
								A2(
								$mdgriffith$elm_ui$Element$row,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
										A2($mdgriffith$elm_ui$Element$spacingXY, 16, 0)
									]),
								_List_fromArray(
									[
										$author$project$Main$barsButton,
										A2(
										$mdgriffith$elm_ui$Element$el,
										_List_fromArray(
											[$mdgriffith$elm_ui$Element$centerY, $mdgriffith$elm_ui$Element$alignLeft]),
										$mdgriffith$elm_ui$Element$text('Slipbox ' + $author$project$Main$versionString))
									])),
								A2(
								$mdgriffith$elm_ui$Element$row,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
										A2($mdgriffith$elm_ui$Element$spacingXY, 16, 0)
									]),
								_List_fromArray(
									[
										emptyIcon,
										A2(
										$mdgriffith$elm_ui$Element$el,
										_List_fromArray(
											[$mdgriffith$elm_ui$Element$centerY, $mdgriffith$elm_ui$Element$alignLeft]),
										$author$project$Main$aboutButton)
									])),
								A2(
								$mdgriffith$elm_ui$Element$el,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
										$mdgriffith$elm_ui$Element$alignBottom
									]),
								A2(
									$mdgriffith$elm_ui$Element$Input$button,
									_List_fromArray(
										[
											$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
											$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
											$mdgriffith$elm_ui$Element$Border$rounded(10),
											$mdgriffith$elm_ui$Element$padding(1)
										]),
									{
										q: A2(
											$mdgriffith$elm_ui$Element$row,
											_List_fromArray(
												[
													A2($mdgriffith$elm_ui$Element$spacingXY, 16, 0),
													$mdgriffith$elm_ui$Element$onRight(unsavedChangesNode)
												]),
											_List_fromArray(
												[
													$author$project$Main$saveIcon,
													$mdgriffith$elm_ui$Element$text('Save')
												])),
										v: $elm$core$Maybe$Just($author$project$Main$FileDownload)
									})),
								A5(
								$author$project$Main$leftNavExpandedButtonLambda,
								$mdgriffith$elm_ui$Element$alignBottom,
								$author$project$Main$plusIcon,
								'Create Mode',
								$author$project$Main$ChangeTab(1),
								A2($author$project$Main$sameTab, selectedTab, 1))
							])),
						A2(
						$mdgriffith$elm_ui$Element$column,
						_List_fromArray(
							[
								$mdgriffith$elm_ui$Element$height($author$project$Main$biggerElement),
								$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
								A2($mdgriffith$elm_ui$Element$spacingXY, 0, 8)
							]),
						_List_fromArray(
							[
								A5(
								$author$project$Main$leftNavExpandedButtonLambda,
								$mdgriffith$elm_ui$Element$alignLeft,
								$author$project$Main$brainIcon,
								'Discovery Mode',
								$author$project$Main$ChangeTab(2),
								A2($author$project$Main$sameTab, selectedTab, 2)),
								A5(
								$author$project$Main$leftNavExpandedButtonLambda,
								$mdgriffith$elm_ui$Element$alignLeft,
								$author$project$Main$toolsIcon,
								'Edit Mode',
								$author$project$Main$ChangeTab(0),
								A2($author$project$Main$sameTab, selectedTab, 0)),
								A5(
								$author$project$Main$leftNavExpandedButtonLambda,
								$mdgriffith$elm_ui$Element$alignLeft,
								$author$project$Main$exportIcon,
								'Export Mode',
								$author$project$Main$ChangeTab(3),
								A2($author$project$Main$sameTab, selectedTab, 3))
							]))
					]));
		} else {
			return A2(
				$mdgriffith$elm_ui$Element$column,
				_List_fromArray(
					[
						$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
						$mdgriffith$elm_ui$Element$width(
						$mdgriffith$elm_ui$Element$px(64)),
						$mdgriffith$elm_ui$Element$padding(8),
						A2($mdgriffith$elm_ui$Element$spacingXY, 0, 8)
					]),
				_List_fromArray(
					[
						A2(
						$mdgriffith$elm_ui$Element$column,
						_List_fromArray(
							[
								$mdgriffith$elm_ui$Element$height($author$project$Main$smallerElement),
								A2($mdgriffith$elm_ui$Element$spacingXY, 0, 8)
							]),
						_List_fromArray(
							[
								$author$project$Main$barsButton,
								A4($author$project$Main$leftNavContractedButtonLambda, $mdgriffith$elm_ui$Element$alignBottom, $author$project$Main$FileDownload, $author$project$Main$saveIcon, false),
								A4(
								$author$project$Main$leftNavContractedButtonLambda,
								$mdgriffith$elm_ui$Element$alignBottom,
								$author$project$Main$ChangeTab(1),
								$author$project$Main$plusIcon,
								A2($author$project$Main$sameTab, selectedTab, 1))
							])),
						A2(
						$mdgriffith$elm_ui$Element$column,
						_List_fromArray(
							[
								$mdgriffith$elm_ui$Element$height($author$project$Main$biggerElement),
								A2($mdgriffith$elm_ui$Element$spacingXY, 0, 8)
							]),
						_List_fromArray(
							[
								A4(
								$author$project$Main$leftNavContractedButtonLambda,
								$mdgriffith$elm_ui$Element$alignLeft,
								$author$project$Main$ChangeTab(2),
								$author$project$Main$brainIcon,
								A2($author$project$Main$sameTab, selectedTab, 2)),
								A4(
								$author$project$Main$leftNavContractedButtonLambda,
								$mdgriffith$elm_ui$Element$alignLeft,
								$author$project$Main$ChangeTab(0),
								$author$project$Main$toolsIcon,
								A2($author$project$Main$sameTab, selectedTab, 0)),
								A4(
								$author$project$Main$leftNavContractedButtonLambda,
								$mdgriffith$elm_ui$Element$alignLeft,
								$author$project$Main$ChangeTab(3),
								$author$project$Main$exportIcon,
								A2($author$project$Main$sameTab, selectedTab, 3))
							]))
					]));
		}
	});
var $author$project$Main$ConfirmBreakLink = function (a) {
	return {$: 0, a: a};
};
var $author$project$Main$CreateTabContinueWithSelectedSource = function (a) {
	return {$: 16, a: a};
};
var $author$project$Main$CreateTabCreateAnotherNote = {$: 21};
var $author$project$Main$CreateTabCreateLinkForSelectedNote = {$: 13};
var $author$project$Main$CreateTabNewSource = {$: 18};
var $author$project$Main$CreateTabNextStep = {$: 10};
var $author$project$Main$CreateTabNoSource = {$: 17};
var $author$project$Main$CreateTabRemoveLink = {$: 14};
var $author$project$Main$CreateTabSubmitNewDiscussion = {$: 22};
var $author$project$Main$CreateTabSubmitNewSource = {$: 19};
var $author$project$Main$CreateTabToChooseDiscussion = {$: 12};
var $author$project$Main$CreateTabToFindLinksForDiscussion = function (a) {
	return {$: 11, a: a};
};
var $author$project$Main$CreateTabUpdateInput = function (a) {
	return {$: 20, a: a};
};
var $author$project$Main$DiscoveryModeBack = {$: 27};
var $author$project$Main$DiscoveryModeSelectDiscussion = function (a) {
	return {$: 26, a: a};
};
var $author$project$Main$DiscoveryModeStartNewDiscussion = {$: 30};
var $author$project$Main$DiscoveryModeSubmit = {$: 29};
var $author$project$Main$DiscoveryModeUpdateInput = function (a) {
	return {$: 25, a: a};
};
var $author$project$Main$DiscussionChosenView = function (a) {
	return {$: 1, a: a};
};
var $author$project$Main$EditModeCancel = {$: 37};
var $author$project$Main$EditModeConfirm = {$: 38};
var $author$project$Main$EditModeConfirmBreakLink = F2(
	function (a, b) {
		return {$: 35, a: a, b: b};
	});
var $author$project$Main$EditModeSelectNote = function (a) {
	return {$: 34, a: a};
};
var $author$project$Main$EditModeSelectNoteScreen = {$: 41};
var $author$project$Main$EditModeUpdateInput = function (a) {
	return {$: 33, a: a};
};
var $author$project$Main$ExportModeContinue = {$: 42};
var $author$project$Main$ExportModeFinish = {$: 46};
var $author$project$Main$ExportModeRemove = function (a) {
	return {$: 45, a: a};
};
var $author$project$Main$ExportModeToggleDiscussion = function (a) {
	return {$: 44, a: a};
};
var $author$project$Main$ExportModeUpdateInput = function (a) {
	return {$: 43, a: a};
};
var $author$project$Create$Note = function (a) {
	return {$: 0, a: a};
};
var $author$project$Create$SourceAuthor = function (a) {
	return {$: 2, a: a};
};
var $author$project$Create$SourceContent = function (a) {
	return {$: 3, a: a};
};
var $author$project$Create$SourceTitle = function (a) {
	return {$: 1, a: a};
};
var $author$project$Main$ViewDiscussionView = {$: 2};
var $mdgriffith$elm_ui$Internal$Model$Right = 2;
var $mdgriffith$elm_ui$Element$alignRight = $mdgriffith$elm_ui$Internal$Model$AlignX(2);
var $mdgriffith$elm_ui$Internal$Flag$fontWeight = $mdgriffith$elm_ui$Internal$Flag$flag(13);
var $mdgriffith$elm_ui$Element$Font$bold = A2($mdgriffith$elm_ui$Internal$Model$Class, $mdgriffith$elm_ui$Internal$Flag$fontWeight, $mdgriffith$elm_ui$Internal$Style$classes.f1);
var $mdgriffith$elm_ui$Internal$Model$CenterX = 1;
var $mdgriffith$elm_ui$Element$centerX = $mdgriffith$elm_ui$Internal$Model$AlignX(1);
var $mdgriffith$elm_ui$Internal$Model$BorderWidth = F5(
	function (a, b, c, d, e) {
		return {$: 6, a: a, b: b, c: c, d: d, e: e};
	});
var $mdgriffith$elm_ui$Element$Border$width = function (v) {
	return A2(
		$mdgriffith$elm_ui$Internal$Model$StyleClass,
		$mdgriffith$elm_ui$Internal$Flag$borderWidth,
		A5(
			$mdgriffith$elm_ui$Internal$Model$BorderWidth,
			'b-' + $elm$core$String$fromInt(v),
			v,
			v,
			v,
			v));
};
var $author$project$Main$button = F2(
	function (msg, label) {
		return A2(
			$mdgriffith$elm_ui$Element$Input$button,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$centerX,
					$mdgriffith$elm_ui$Element$padding(8),
					$mdgriffith$elm_ui$Element$Border$width(1)
				]),
			{q: label, v: msg});
	});
var $mdgriffith$elm_ui$Internal$Flag$fontAlignment = $mdgriffith$elm_ui$Internal$Flag$flag(12);
var $mdgriffith$elm_ui$Element$Font$center = A2($mdgriffith$elm_ui$Internal$Model$Class, $mdgriffith$elm_ui$Internal$Flag$fontAlignment, $mdgriffith$elm_ui$Internal$Style$classes.hO);
var $author$project$Main$CreateTabToggleCoaching = {$: 9};
var $author$project$Main$coaching = F2(
	function (coachingOpen, text) {
		var toggleCoachingButton = A2(
			$mdgriffith$elm_ui$Element$Input$button,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$centerX,
					$mdgriffith$elm_ui$Element$Border$width(1),
					$mdgriffith$elm_ui$Element$Border$rounded(4),
					$mdgriffith$elm_ui$Element$padding(2)
				]),
			{
				q: $mdgriffith$elm_ui$Element$text('Coaching'),
				v: $elm$core$Maybe$Just($author$project$Main$CreateTabToggleCoaching)
			});
		if (!coachingOpen) {
			return toggleCoachingButton;
		} else {
			return A2(
				$mdgriffith$elm_ui$Element$column,
				_List_fromArray(
					[
						A2($mdgriffith$elm_ui$Element$spacingXY, 8, 8),
						$mdgriffith$elm_ui$Element$centerX
					]),
				_List_fromArray(
					[toggleCoachingButton, text]));
		}
	});
var $author$project$Main$column = function (contents) {
	return A2(
		$mdgriffith$elm_ui$Element$column,
		_List_fromArray(
			[
				$mdgriffith$elm_ui$Element$padding(16),
				$mdgriffith$elm_ui$Element$centerX,
				$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
				A2($mdgriffith$elm_ui$Element$spacingXY, 32, 32)
			]),
		contents);
};
var $elm$html$Html$datalist = _VirtualDom_node('datalist');
var $elm$html$Html$Attributes$for = $elm$html$Html$Attributes$stringProperty('htmlFor');
var $elm$html$Html$Attributes$id = $elm$html$Html$Attributes$stringProperty('id');
var $elm$html$Html$input = _VirtualDom_node('input');
var $elm$html$Html$label = _VirtualDom_node('label');
var $elm$html$Html$Attributes$list = _VirtualDom_attribute('list');
var $elm$html$Html$Attributes$name = $elm$html$Html$Attributes$stringProperty('name');
var $elm$html$Html$Events$alwaysStop = function (x) {
	return _Utils_Tuple2(x, true);
};
var $elm$virtual_dom$VirtualDom$MayStopPropagation = function (a) {
	return {$: 1, a: a};
};
var $elm$html$Html$Events$stopPropagationOn = F2(
	function (event, decoder) {
		return A2(
			$elm$virtual_dom$VirtualDom$on,
			event,
			$elm$virtual_dom$VirtualDom$MayStopPropagation(decoder));
	});
var $elm$json$Json$Decode$at = F2(
	function (fields, decoder) {
		return A3($elm$core$List$foldr, $elm$json$Json$Decode$field, decoder, fields);
	});
var $elm$html$Html$Events$targetValue = A2(
	$elm$json$Json$Decode$at,
	_List_fromArray(
		['target', 'value']),
	$elm$json$Json$Decode$string);
var $elm$html$Html$Events$onInput = function (tagger) {
	return A2(
		$elm$html$Html$Events$stopPropagationOn,
		'input',
		A2(
			$elm$json$Json$Decode$map,
			$elm$html$Html$Events$alwaysStop,
			A2($elm$json$Json$Decode$map, tagger, $elm$html$Html$Events$targetValue)));
};
var $elm$html$Html$option = _VirtualDom_node('option');
var $elm$html$Html$Attributes$value = $elm$html$Html$Attributes$stringProperty('value');
var $author$project$Main$toHtmlOption = function (value) {
	return A2(
		$elm$html$Html$option,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$value(value)
			]),
		_List_Nil);
};
var $author$project$Main$createTabSourceInput = F2(
	function (input, suggestions) {
		var sourceInputid = 'Source: 1';
		var dataitemId = 'Sources: 2';
		return $mdgriffith$elm_ui$Element$html(
			A2(
				$elm$html$Html$div,
				_List_Nil,
				_List_fromArray(
					[
						A2(
						$elm$html$Html$label,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$for(sourceInputid)
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('Source: ')
							])),
						A2(
						$elm$html$Html$input,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$list(dataitemId),
								$elm$html$Html$Attributes$name(sourceInputid),
								$elm$html$Html$Attributes$id(sourceInputid),
								$elm$html$Html$Attributes$value(input),
								$elm$html$Html$Events$onInput(
								function (s) {
									return $author$project$Main$CreateTabUpdateInput(
										$author$project$Create$SourceTitle(s));
								})
							]),
						_List_Nil),
						A2(
						$elm$html$Html$datalist,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$id(dataitemId)
							]),
						A2($elm$core$List$map, $author$project$Main$toHtmlOption, suggestions))
					])));
	});
var $author$project$Slipbox$isNote = function (note) {
	return !$author$project$Note$getVariant(note);
};
var $author$project$Slipbox$getNotes = F2(
	function (maybeSearch, slipbox) {
		var content = $author$project$Slipbox$getContent(slipbox);
		if (!maybeSearch.$) {
			var search = maybeSearch.a;
			return A2(
				$elm$core$List$filter,
				$author$project$Slipbox$isNote,
				A2(
					$elm$core$List$filter,
					$author$project$Note$contains(search),
					content.R));
		} else {
			return A2($elm$core$List$filter, $author$project$Slipbox$isNote, content.R);
		}
	});
var $mdgriffith$elm_ui$Internal$Model$Paragraph = {$: 9};
var $mdgriffith$elm_ui$Element$spacing = function (x) {
	return A2(
		$mdgriffith$elm_ui$Internal$Model$StyleClass,
		$mdgriffith$elm_ui$Internal$Flag$spacing,
		A3(
			$mdgriffith$elm_ui$Internal$Model$SpacingStyle,
			A2($mdgriffith$elm_ui$Internal$Model$spacingName, x, x),
			x,
			x));
};
var $mdgriffith$elm_ui$Element$paragraph = F2(
	function (attrs, children) {
		return A4(
			$mdgriffith$elm_ui$Internal$Model$element,
			$mdgriffith$elm_ui$Internal$Model$asParagraph,
			$mdgriffith$elm_ui$Internal$Model$div,
			A2(
				$elm$core$List$cons,
				$mdgriffith$elm_ui$Internal$Model$Describe($mdgriffith$elm_ui$Internal$Model$Paragraph),
				A2(
					$elm$core$List$cons,
					$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
					A2(
						$elm$core$List$cons,
						$mdgriffith$elm_ui$Element$spacing(5),
						attrs))),
			$mdgriffith$elm_ui$Internal$Model$Unkeyed(children));
	});
var $author$project$Main$heading = function (title) {
	return A2(
		$mdgriffith$elm_ui$Element$paragraph,
		_List_fromArray(
			[$mdgriffith$elm_ui$Element$Font$bold]),
		_List_fromArray(
			[
				$mdgriffith$elm_ui$Element$text(title)
			]));
};
var $author$project$Main$headingCenter = function (title) {
	return A2(
		$mdgriffith$elm_ui$Element$el,
		_List_fromArray(
			[$mdgriffith$elm_ui$Element$centerX]),
		$author$project$Main$heading(title));
};
var $author$project$Main$leftPad = {aM: 0, aT: 8, aZ: 0, a_: 0};
var $author$project$Main$listButton = F2(
	function (onPress, label) {
		return A2(
			$mdgriffith$elm_ui$Element$Input$button,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$Border$width(2),
					$mdgriffith$elm_ui$Element$padding(8)
				]),
			{q: label, v: onPress});
	});
var $author$project$Main$rightWidth = {aM: 0, aT: 0, aZ: 1, a_: 0};
var $mdgriffith$elm_ui$Element$Border$widthXY = F2(
	function (x, y) {
		return A2(
			$mdgriffith$elm_ui$Internal$Model$StyleClass,
			$mdgriffith$elm_ui$Internal$Flag$borderWidth,
			A5(
				$mdgriffith$elm_ui$Internal$Model$BorderWidth,
				'b-' + ($elm$core$String$fromInt(x) + ('-' + $elm$core$String$fromInt(y))),
				y,
				x,
				y,
				x));
	});
var $mdgriffith$elm_ui$Element$Border$widthEach = function (_v0) {
	var bottom = _v0.aM;
	var top = _v0.a_;
	var left = _v0.aT;
	var right = _v0.aZ;
	return (_Utils_eq(top, bottom) && _Utils_eq(left, right)) ? (_Utils_eq(top, right) ? $mdgriffith$elm_ui$Element$Border$width(top) : A2($mdgriffith$elm_ui$Element$Border$widthXY, left, top)) : A2(
		$mdgriffith$elm_ui$Internal$Model$StyleClass,
		$mdgriffith$elm_ui$Internal$Flag$borderWidth,
		A5(
			$mdgriffith$elm_ui$Internal$Model$BorderWidth,
			'b-' + ($elm$core$String$fromInt(top) + ('-' + ($elm$core$String$fromInt(right) + ('-' + ($elm$core$String$fromInt(bottom) + ('-' + $elm$core$String$fromInt(left))))))),
			top,
			right,
			bottom,
			left));
};
var $author$project$Main$listButtonWithBreakLink = F3(
	function (cancelPress, onPress, label) {
		return A2(
			$mdgriffith$elm_ui$Element$row,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$Border$width(1),
					$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
				]),
			_List_fromArray(
				[
					A2(
					$mdgriffith$elm_ui$Element$Input$button,
					_List_fromArray(
						[
							$mdgriffith$elm_ui$Element$Border$widthEach($author$project$Main$rightWidth),
							$mdgriffith$elm_ui$Element$padding(8),
							$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
						]),
					{q: label, v: onPress}),
					A2(
					$mdgriffith$elm_ui$Element$Input$button,
					_List_fromArray(
						[
							$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
							$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$shrink),
							$mdgriffith$elm_ui$Element$padding(8)
						]),
					{
						q: A2(
							$mdgriffith$elm_ui$Element$el,
							_List_fromArray(
								[$mdgriffith$elm_ui$Element$centerX, $mdgriffith$elm_ui$Element$centerY]),
							$mdgriffith$elm_ui$Element$text('Break Link')),
						v: cancelPress
					})
				]));
	});
var $mdgriffith$elm_ui$Internal$Model$Max = F2(
	function (a, b) {
		return {$: 4, a: a, b: b};
	});
var $mdgriffith$elm_ui$Element$maximum = F2(
	function (i, l) {
		return A2($mdgriffith$elm_ui$Internal$Model$Max, i, l);
	});
var $mdgriffith$elm_ui$Internal$Model$Min = F2(
	function (a, b) {
		return {$: 3, a: a, b: b};
	});
var $mdgriffith$elm_ui$Element$minimum = F2(
	function (i, l) {
		return A2($mdgriffith$elm_ui$Internal$Model$Min, i, l);
	});
var $mdgriffith$elm_ui$Element$Input$Above = 2;
var $mdgriffith$elm_ui$Element$Input$Label = F3(
	function (a, b, c) {
		return {$: 0, a: a, b: b, c: c};
	});
var $mdgriffith$elm_ui$Element$Input$labelAbove = $mdgriffith$elm_ui$Element$Input$Label(2);
var $mdgriffith$elm_ui$Element$Input$TextArea = {$: 1};
var $mdgriffith$elm_ui$Internal$Model$LivePolite = {$: 6};
var $mdgriffith$elm_ui$Element$Region$announce = $mdgriffith$elm_ui$Internal$Model$Describe($mdgriffith$elm_ui$Internal$Model$LivePolite);
var $mdgriffith$elm_ui$Element$Input$applyLabel = F3(
	function (attrs, label, input) {
		if (label.$ === 1) {
			var labelText = label.a;
			return A4(
				$mdgriffith$elm_ui$Internal$Model$element,
				$mdgriffith$elm_ui$Internal$Model$asColumn,
				$mdgriffith$elm_ui$Internal$Model$NodeName('label'),
				attrs,
				$mdgriffith$elm_ui$Internal$Model$Unkeyed(
					_List_fromArray(
						[input])));
		} else {
			var position = label.a;
			var labelAttrs = label.b;
			var labelChild = label.c;
			var labelElement = A4(
				$mdgriffith$elm_ui$Internal$Model$element,
				$mdgriffith$elm_ui$Internal$Model$asEl,
				$mdgriffith$elm_ui$Internal$Model$div,
				labelAttrs,
				$mdgriffith$elm_ui$Internal$Model$Unkeyed(
					_List_fromArray(
						[labelChild])));
			switch (position) {
				case 2:
					return A4(
						$mdgriffith$elm_ui$Internal$Model$element,
						$mdgriffith$elm_ui$Internal$Model$asColumn,
						$mdgriffith$elm_ui$Internal$Model$NodeName('label'),
						A2(
							$elm$core$List$cons,
							$mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.cb),
							attrs),
						$mdgriffith$elm_ui$Internal$Model$Unkeyed(
							_List_fromArray(
								[labelElement, input])));
				case 3:
					return A4(
						$mdgriffith$elm_ui$Internal$Model$element,
						$mdgriffith$elm_ui$Internal$Model$asColumn,
						$mdgriffith$elm_ui$Internal$Model$NodeName('label'),
						A2(
							$elm$core$List$cons,
							$mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.cb),
							attrs),
						$mdgriffith$elm_ui$Internal$Model$Unkeyed(
							_List_fromArray(
								[input, labelElement])));
				case 0:
					return A4(
						$mdgriffith$elm_ui$Internal$Model$element,
						$mdgriffith$elm_ui$Internal$Model$asRow,
						$mdgriffith$elm_ui$Internal$Model$NodeName('label'),
						A2(
							$elm$core$List$cons,
							$mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.cb),
							attrs),
						$mdgriffith$elm_ui$Internal$Model$Unkeyed(
							_List_fromArray(
								[input, labelElement])));
				default:
					return A4(
						$mdgriffith$elm_ui$Internal$Model$element,
						$mdgriffith$elm_ui$Internal$Model$asRow,
						$mdgriffith$elm_ui$Internal$Model$NodeName('label'),
						A2(
							$elm$core$List$cons,
							$mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.cb),
							attrs),
						$mdgriffith$elm_ui$Internal$Model$Unkeyed(
							_List_fromArray(
								[labelElement, input])));
			}
		}
	});
var $mdgriffith$elm_ui$Element$Input$autofill = A2(
	$elm$core$Basics$composeL,
	$mdgriffith$elm_ui$Internal$Model$Attr,
	$elm$html$Html$Attributes$attribute('autocomplete'));
var $mdgriffith$elm_ui$Internal$Model$Behind = 5;
var $mdgriffith$elm_ui$Element$behindContent = function (element) {
	return A2($mdgriffith$elm_ui$Element$createNearby, 5, element);
};
var $mdgriffith$elm_ui$Element$moveUp = function (y) {
	return A2(
		$mdgriffith$elm_ui$Internal$Model$TransformComponent,
		$mdgriffith$elm_ui$Internal$Flag$moveY,
		$mdgriffith$elm_ui$Internal$Model$MoveY(-y));
};
var $mdgriffith$elm_ui$Element$Input$calcMoveToCompensateForPadding = function (attrs) {
	var gatherSpacing = F2(
		function (attr, found) {
			if ((attr.$ === 4) && (attr.b.$ === 5)) {
				var _v2 = attr.b;
				var x = _v2.b;
				var y = _v2.c;
				if (found.$ === 1) {
					return $elm$core$Maybe$Just(y);
				} else {
					return found;
				}
			} else {
				return found;
			}
		});
	var _v0 = A3($elm$core$List$foldr, gatherSpacing, $elm$core$Maybe$Nothing, attrs);
	if (_v0.$ === 1) {
		return $mdgriffith$elm_ui$Internal$Model$NoAttribute;
	} else {
		var vSpace = _v0.a;
		return $mdgriffith$elm_ui$Element$moveUp(
			$elm$core$Basics$floor(vSpace / 2));
	}
};
var $mdgriffith$elm_ui$Internal$Flag$overflow = $mdgriffith$elm_ui$Internal$Flag$flag(20);
var $mdgriffith$elm_ui$Element$clip = A2($mdgriffith$elm_ui$Internal$Model$Class, $mdgriffith$elm_ui$Internal$Flag$overflow, $mdgriffith$elm_ui$Internal$Style$classes.gb);
var $mdgriffith$elm_ui$Internal$Flag$borderColor = $mdgriffith$elm_ui$Internal$Flag$flag(28);
var $mdgriffith$elm_ui$Element$Border$color = function (clr) {
	return A2(
		$mdgriffith$elm_ui$Internal$Model$StyleClass,
		$mdgriffith$elm_ui$Internal$Flag$borderColor,
		A3(
			$mdgriffith$elm_ui$Internal$Model$Colored,
			'bc-' + $mdgriffith$elm_ui$Internal$Model$formatColorClass(clr),
			'border-color',
			clr));
};
var $mdgriffith$elm_ui$Element$rgb = F3(
	function (r, g, b) {
		return A4($mdgriffith$elm_ui$Internal$Model$Rgba, r, g, b, 1);
	});
var $mdgriffith$elm_ui$Element$Input$darkGrey = A3($mdgriffith$elm_ui$Element$rgb, 186 / 255, 189 / 255, 182 / 255);
var $mdgriffith$elm_ui$Element$paddingXY = F2(
	function (x, y) {
		if (_Utils_eq(x, y)) {
			var f = x;
			return A2(
				$mdgriffith$elm_ui$Internal$Model$StyleClass,
				$mdgriffith$elm_ui$Internal$Flag$padding,
				A5(
					$mdgriffith$elm_ui$Internal$Model$PaddingStyle,
					'p-' + $elm$core$String$fromInt(x),
					f,
					f,
					f,
					f));
		} else {
			var yFloat = y;
			var xFloat = x;
			return A2(
				$mdgriffith$elm_ui$Internal$Model$StyleClass,
				$mdgriffith$elm_ui$Internal$Flag$padding,
				A5(
					$mdgriffith$elm_ui$Internal$Model$PaddingStyle,
					'p-' + ($elm$core$String$fromInt(x) + ('-' + $elm$core$String$fromInt(y))),
					yFloat,
					xFloat,
					yFloat,
					xFloat));
		}
	});
var $mdgriffith$elm_ui$Element$Input$defaultTextPadding = A2($mdgriffith$elm_ui$Element$paddingXY, 12, 12);
var $mdgriffith$elm_ui$Element$Input$white = A3($mdgriffith$elm_ui$Element$rgb, 1, 1, 1);
var $mdgriffith$elm_ui$Element$Input$defaultTextBoxStyle = _List_fromArray(
	[
		$mdgriffith$elm_ui$Element$Input$defaultTextPadding,
		$mdgriffith$elm_ui$Element$Border$rounded(3),
		$mdgriffith$elm_ui$Element$Border$color($mdgriffith$elm_ui$Element$Input$darkGrey),
		$mdgriffith$elm_ui$Element$Background$color($mdgriffith$elm_ui$Element$Input$white),
		$mdgriffith$elm_ui$Element$Border$width(1),
		$mdgriffith$elm_ui$Element$spacing(5),
		$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
		$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$shrink)
	]);
var $mdgriffith$elm_ui$Element$Input$getHeight = function (attr) {
	if (attr.$ === 8) {
		var h = attr.a;
		return $elm$core$Maybe$Just(h);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $mdgriffith$elm_ui$Internal$Model$Label = function (a) {
	return {$: 5, a: a};
};
var $mdgriffith$elm_ui$Element$Input$hiddenLabelAttribute = function (label) {
	if (label.$ === 1) {
		var textLabel = label.a;
		return $mdgriffith$elm_ui$Internal$Model$Describe(
			$mdgriffith$elm_ui$Internal$Model$Label(textLabel));
	} else {
		return $mdgriffith$elm_ui$Internal$Model$NoAttribute;
	}
};
var $mdgriffith$elm_ui$Internal$Model$InFront = 4;
var $mdgriffith$elm_ui$Element$inFront = function (element) {
	return A2($mdgriffith$elm_ui$Element$createNearby, 4, element);
};
var $mdgriffith$elm_ui$Element$Input$isConstrained = function (len) {
	isConstrained:
	while (true) {
		switch (len.$) {
			case 1:
				return false;
			case 0:
				return true;
			case 2:
				return true;
			case 3:
				var l = len.b;
				var $temp$len = l;
				len = $temp$len;
				continue isConstrained;
			default:
				var l = len.b;
				return true;
		}
	}
};
var $mdgriffith$elm_ui$Element$Input$isHiddenLabel = function (label) {
	if (label.$ === 1) {
		return true;
	} else {
		return false;
	}
};
var $mdgriffith$elm_ui$Element$Input$isStacked = function (label) {
	if (!label.$) {
		var loc = label.a;
		switch (loc) {
			case 0:
				return false;
			case 1:
				return false;
			case 2:
				return true;
			default:
				return true;
		}
	} else {
		return true;
	}
};
var $mdgriffith$elm_ui$Element$Input$negateBox = function (box) {
	return {aM: -box.aM, aT: -box.aT, aZ: -box.aZ, a_: -box.a_};
};
var $mdgriffith$elm_ui$Internal$Model$paddingName = F4(
	function (top, right, bottom, left) {
		return 'pad-' + ($elm$core$String$fromInt(top) + ('-' + ($elm$core$String$fromInt(right) + ('-' + ($elm$core$String$fromInt(bottom) + ('-' + $elm$core$String$fromInt(left)))))));
	});
var $mdgriffith$elm_ui$Element$paddingEach = function (_v0) {
	var top = _v0.a_;
	var right = _v0.aZ;
	var bottom = _v0.aM;
	var left = _v0.aT;
	if (_Utils_eq(top, right) && (_Utils_eq(top, bottom) && _Utils_eq(top, left))) {
		var topFloat = top;
		return A2(
			$mdgriffith$elm_ui$Internal$Model$StyleClass,
			$mdgriffith$elm_ui$Internal$Flag$padding,
			A5(
				$mdgriffith$elm_ui$Internal$Model$PaddingStyle,
				'p-' + $elm$core$String$fromInt(top),
				topFloat,
				topFloat,
				topFloat,
				topFloat));
	} else {
		return A2(
			$mdgriffith$elm_ui$Internal$Model$StyleClass,
			$mdgriffith$elm_ui$Internal$Flag$padding,
			A5(
				$mdgriffith$elm_ui$Internal$Model$PaddingStyle,
				A4($mdgriffith$elm_ui$Internal$Model$paddingName, top, right, bottom, left),
				top,
				right,
				bottom,
				left));
	}
};
var $mdgriffith$elm_ui$Element$htmlAttribute = $mdgriffith$elm_ui$Internal$Model$Attr;
var $mdgriffith$elm_ui$Element$Input$isFill = function (len) {
	isFill:
	while (true) {
		switch (len.$) {
			case 2:
				return true;
			case 1:
				return false;
			case 0:
				return false;
			case 3:
				var l = len.b;
				var $temp$len = l;
				len = $temp$len;
				continue isFill;
			default:
				var l = len.b;
				var $temp$len = l;
				len = $temp$len;
				continue isFill;
		}
	}
};
var $mdgriffith$elm_ui$Element$Input$isPixel = function (len) {
	isPixel:
	while (true) {
		switch (len.$) {
			case 1:
				return false;
			case 0:
				return true;
			case 2:
				return false;
			case 3:
				var l = len.b;
				var $temp$len = l;
				len = $temp$len;
				continue isPixel;
			default:
				var l = len.b;
				var $temp$len = l;
				len = $temp$len;
				continue isPixel;
		}
	}
};
var $mdgriffith$elm_ui$Internal$Model$paddingNameFloat = F4(
	function (top, right, bottom, left) {
		return 'pad-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(top) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(right) + ('-' + ($mdgriffith$elm_ui$Internal$Model$floatClass(bottom) + ('-' + $mdgriffith$elm_ui$Internal$Model$floatClass(left)))))));
	});
var $mdgriffith$elm_ui$Element$Input$redistributeOver = F4(
	function (isMultiline, stacked, attr, els) {
		switch (attr.$) {
			case 9:
				return _Utils_update(
					els,
					{
						c: A2($elm$core$List$cons, attr, els.c)
					});
			case 7:
				var width = attr.a;
				return $mdgriffith$elm_ui$Element$Input$isFill(width) ? _Utils_update(
					els,
					{
						m: A2($elm$core$List$cons, attr, els.m),
						u: A2($elm$core$List$cons, attr, els.u),
						c: A2($elm$core$List$cons, attr, els.c)
					}) : (stacked ? _Utils_update(
					els,
					{
						m: A2($elm$core$List$cons, attr, els.m)
					}) : _Utils_update(
					els,
					{
						c: A2($elm$core$List$cons, attr, els.c)
					}));
			case 8:
				var height = attr.a;
				return (!stacked) ? _Utils_update(
					els,
					{
						m: A2($elm$core$List$cons, attr, els.m),
						c: A2($elm$core$List$cons, attr, els.c)
					}) : ($mdgriffith$elm_ui$Element$Input$isFill(height) ? _Utils_update(
					els,
					{
						m: A2($elm$core$List$cons, attr, els.m),
						c: A2($elm$core$List$cons, attr, els.c)
					}) : ($mdgriffith$elm_ui$Element$Input$isPixel(height) ? _Utils_update(
					els,
					{
						c: A2($elm$core$List$cons, attr, els.c)
					}) : _Utils_update(
					els,
					{
						c: A2($elm$core$List$cons, attr, els.c)
					})));
			case 6:
				return _Utils_update(
					els,
					{
						m: A2($elm$core$List$cons, attr, els.m)
					});
			case 5:
				return _Utils_update(
					els,
					{
						m: A2($elm$core$List$cons, attr, els.m)
					});
			case 4:
				switch (attr.b.$) {
					case 5:
						var _v1 = attr.b;
						return _Utils_update(
							els,
							{
								m: A2($elm$core$List$cons, attr, els.m),
								u: A2($elm$core$List$cons, attr, els.u),
								c: A2($elm$core$List$cons, attr, els.c),
								br: A2($elm$core$List$cons, attr, els.br)
							});
					case 7:
						var cls = attr.a;
						var _v2 = attr.b;
						var pad = _v2.a;
						var t = _v2.b;
						var r = _v2.c;
						var b = _v2.d;
						var l = _v2.e;
						if (isMultiline) {
							return _Utils_update(
								els,
								{
									L: A2($elm$core$List$cons, attr, els.L),
									c: A2($elm$core$List$cons, attr, els.c)
								});
						} else {
							var newTop = t - A2($elm$core$Basics$min, t, b);
							var newLineHeight = $mdgriffith$elm_ui$Element$htmlAttribute(
								A2(
									$elm$html$Html$Attributes$style,
									'line-height',
									'calc(1.0em + ' + ($elm$core$String$fromFloat(
										2 * A2($elm$core$Basics$min, t, b)) + 'px)')));
							var newHeight = $mdgriffith$elm_ui$Element$htmlAttribute(
								A2(
									$elm$html$Html$Attributes$style,
									'height',
									'calc(1.0em + ' + ($elm$core$String$fromFloat(
										2 * A2($elm$core$Basics$min, t, b)) + 'px)')));
							var newBottom = b - A2($elm$core$Basics$min, t, b);
							var reducedVerticalPadding = A2(
								$mdgriffith$elm_ui$Internal$Model$StyleClass,
								$mdgriffith$elm_ui$Internal$Flag$padding,
								A5(
									$mdgriffith$elm_ui$Internal$Model$PaddingStyle,
									A4($mdgriffith$elm_ui$Internal$Model$paddingNameFloat, newTop, r, newBottom, l),
									newTop,
									r,
									newBottom,
									l));
							return _Utils_update(
								els,
								{
									L: A2($elm$core$List$cons, attr, els.L),
									u: A2(
										$elm$core$List$cons,
										newHeight,
										A2($elm$core$List$cons, newLineHeight, els.u)),
									c: A2($elm$core$List$cons, reducedVerticalPadding, els.c)
								});
						}
					case 6:
						var _v3 = attr.b;
						return _Utils_update(
							els,
							{
								L: A2($elm$core$List$cons, attr, els.L),
								c: A2($elm$core$List$cons, attr, els.c)
							});
					case 10:
						return _Utils_update(
							els,
							{
								L: A2($elm$core$List$cons, attr, els.L),
								c: A2($elm$core$List$cons, attr, els.c)
							});
					case 2:
						return _Utils_update(
							els,
							{
								m: A2($elm$core$List$cons, attr, els.m)
							});
					case 1:
						var _v4 = attr.b;
						return _Utils_update(
							els,
							{
								m: A2($elm$core$List$cons, attr, els.m)
							});
					default:
						var flag = attr.a;
						var cls = attr.b;
						return _Utils_update(
							els,
							{
								c: A2($elm$core$List$cons, attr, els.c)
							});
				}
			case 0:
				return els;
			case 1:
				var a = attr.a;
				return _Utils_update(
					els,
					{
						u: A2($elm$core$List$cons, attr, els.u)
					});
			case 2:
				return _Utils_update(
					els,
					{
						u: A2($elm$core$List$cons, attr, els.u)
					});
			case 3:
				return _Utils_update(
					els,
					{
						c: A2($elm$core$List$cons, attr, els.c)
					});
			default:
				return _Utils_update(
					els,
					{
						u: A2($elm$core$List$cons, attr, els.u)
					});
		}
	});
var $mdgriffith$elm_ui$Element$Input$redistribute = F3(
	function (isMultiline, stacked, attrs) {
		return function (redist) {
			return {
				L: $elm$core$List$reverse(redist.L),
				m: $elm$core$List$reverse(redist.m),
				u: $elm$core$List$reverse(redist.u),
				c: $elm$core$List$reverse(redist.c),
				br: $elm$core$List$reverse(redist.br)
			};
		}(
			A3(
				$elm$core$List$foldl,
				A2($mdgriffith$elm_ui$Element$Input$redistributeOver, isMultiline, stacked),
				{L: _List_Nil, m: _List_Nil, u: _List_Nil, c: _List_Nil, br: _List_Nil},
				attrs));
	});
var $mdgriffith$elm_ui$Element$Input$renderBox = function (_v0) {
	var top = _v0.a_;
	var right = _v0.aZ;
	var bottom = _v0.aM;
	var left = _v0.aT;
	return $elm$core$String$fromInt(top) + ('px ' + ($elm$core$String$fromInt(right) + ('px ' + ($elm$core$String$fromInt(bottom) + ('px ' + ($elm$core$String$fromInt(left) + 'px'))))));
};
var $mdgriffith$elm_ui$Internal$Model$Transparency = F2(
	function (a, b) {
		return {$: 12, a: a, b: b};
	});
var $mdgriffith$elm_ui$Internal$Flag$transparency = $mdgriffith$elm_ui$Internal$Flag$flag(0);
var $mdgriffith$elm_ui$Element$alpha = function (o) {
	var transparency = function (x) {
		return 1 - x;
	}(
		A2(
			$elm$core$Basics$min,
			1.0,
			A2($elm$core$Basics$max, 0.0, o)));
	return A2(
		$mdgriffith$elm_ui$Internal$Model$StyleClass,
		$mdgriffith$elm_ui$Internal$Flag$transparency,
		A2(
			$mdgriffith$elm_ui$Internal$Model$Transparency,
			'transparency-' + $mdgriffith$elm_ui$Internal$Model$floatClass(transparency),
			transparency));
};
var $mdgriffith$elm_ui$Element$Input$charcoal = A3($mdgriffith$elm_ui$Element$rgb, 136 / 255, 138 / 255, 133 / 255);
var $mdgriffith$elm_ui$Element$Font$color = function (fontColor) {
	return A2(
		$mdgriffith$elm_ui$Internal$Model$StyleClass,
		$mdgriffith$elm_ui$Internal$Flag$fontColor,
		A3(
			$mdgriffith$elm_ui$Internal$Model$Colored,
			'fc-' + $mdgriffith$elm_ui$Internal$Model$formatColorClass(fontColor),
			'color',
			fontColor));
};
var $mdgriffith$elm_ui$Element$rgba = $mdgriffith$elm_ui$Internal$Model$Rgba;
var $mdgriffith$elm_ui$Element$Input$renderPlaceholder = F3(
	function (_v0, forPlaceholder, on) {
		var placeholderAttrs = _v0.a;
		var placeholderEl = _v0.b;
		return A2(
			$mdgriffith$elm_ui$Element$el,
			_Utils_ap(
				forPlaceholder,
				_Utils_ap(
					_List_fromArray(
						[
							$mdgriffith$elm_ui$Element$Font$color($mdgriffith$elm_ui$Element$Input$charcoal),
							$mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.eV + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.hb)),
							$mdgriffith$elm_ui$Element$clip,
							$mdgriffith$elm_ui$Element$Border$color(
							A4($mdgriffith$elm_ui$Element$rgba, 0, 0, 0, 0)),
							$mdgriffith$elm_ui$Element$Background$color(
							A4($mdgriffith$elm_ui$Element$rgba, 0, 0, 0, 0)),
							$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
							$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
							$mdgriffith$elm_ui$Element$alpha(
							on ? 1 : 0)
						]),
					placeholderAttrs)),
			placeholderEl);
	});
var $mdgriffith$elm_ui$Element$scrollbarY = A2($mdgriffith$elm_ui$Internal$Model$Class, $mdgriffith$elm_ui$Internal$Flag$overflow, $mdgriffith$elm_ui$Internal$Style$classes.ht);
var $elm$html$Html$span = _VirtualDom_node('span');
var $elm$html$Html$Attributes$spellcheck = $elm$html$Html$Attributes$boolProperty('spellcheck');
var $mdgriffith$elm_ui$Element$Input$spellcheck = A2($elm$core$Basics$composeL, $mdgriffith$elm_ui$Internal$Model$Attr, $elm$html$Html$Attributes$spellcheck);
var $elm$html$Html$Attributes$type_ = $elm$html$Html$Attributes$stringProperty('type');
var $mdgriffith$elm_ui$Element$Input$value = A2($elm$core$Basics$composeL, $mdgriffith$elm_ui$Internal$Model$Attr, $elm$html$Html$Attributes$value);
var $mdgriffith$elm_ui$Element$Input$textHelper = F3(
	function (textInput, attrs, textOptions) {
		var withDefaults = _Utils_ap($mdgriffith$elm_ui$Element$Input$defaultTextBoxStyle, attrs);
		var redistributed = A3(
			$mdgriffith$elm_ui$Element$Input$redistribute,
			_Utils_eq(textInput.B, $mdgriffith$elm_ui$Element$Input$TextArea),
			$mdgriffith$elm_ui$Element$Input$isStacked(textOptions.q),
			withDefaults);
		var onlySpacing = function (attr) {
			if ((attr.$ === 4) && (attr.b.$ === 5)) {
				var _v9 = attr.b;
				return true;
			} else {
				return false;
			}
		};
		var heightConstrained = function () {
			var _v7 = textInput.B;
			if (!_v7.$) {
				var inputType = _v7.a;
				return false;
			} else {
				return A2(
					$elm$core$Maybe$withDefault,
					false,
					A2(
						$elm$core$Maybe$map,
						$mdgriffith$elm_ui$Element$Input$isConstrained,
						$elm$core$List$head(
							$elm$core$List$reverse(
								A2($elm$core$List$filterMap, $mdgriffith$elm_ui$Element$Input$getHeight, withDefaults)))));
			}
		}();
		var getPadding = function (attr) {
			if ((attr.$ === 4) && (attr.b.$ === 7)) {
				var cls = attr.a;
				var _v6 = attr.b;
				var pad = _v6.a;
				var t = _v6.b;
				var r = _v6.c;
				var b = _v6.d;
				var l = _v6.e;
				return $elm$core$Maybe$Just(
					{
						aM: A2(
							$elm$core$Basics$max,
							0,
							$elm$core$Basics$floor(b - 3)),
						aT: A2(
							$elm$core$Basics$max,
							0,
							$elm$core$Basics$floor(l - 3)),
						aZ: A2(
							$elm$core$Basics$max,
							0,
							$elm$core$Basics$floor(r - 3)),
						a_: A2(
							$elm$core$Basics$max,
							0,
							$elm$core$Basics$floor(t - 3))
					});
			} else {
				return $elm$core$Maybe$Nothing;
			}
		};
		var parentPadding = A2(
			$elm$core$Maybe$withDefault,
			{aM: 0, aT: 0, aZ: 0, a_: 0},
			$elm$core$List$head(
				$elm$core$List$reverse(
					A2($elm$core$List$filterMap, getPadding, withDefaults))));
		var inputElement = A4(
			$mdgriffith$elm_ui$Internal$Model$element,
			$mdgriffith$elm_ui$Internal$Model$asEl,
			function () {
				var _v3 = textInput.B;
				if (!_v3.$) {
					var inputType = _v3.a;
					return $mdgriffith$elm_ui$Internal$Model$NodeName('input');
				} else {
					return $mdgriffith$elm_ui$Internal$Model$NodeName('textarea');
				}
			}(),
			_Utils_ap(
				function () {
					var _v4 = textInput.B;
					if (!_v4.$) {
						var inputType = _v4.a;
						return _List_fromArray(
							[
								$mdgriffith$elm_ui$Internal$Model$Attr(
								$elm$html$Html$Attributes$type_(inputType)),
								$mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.gP)
							]);
					} else {
						return _List_fromArray(
							[
								$mdgriffith$elm_ui$Element$clip,
								$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
								$mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.gL),
								$mdgriffith$elm_ui$Element$Input$calcMoveToCompensateForPadding(withDefaults),
								$mdgriffith$elm_ui$Element$paddingEach(parentPadding),
								$mdgriffith$elm_ui$Internal$Model$Attr(
								A2(
									$elm$html$Html$Attributes$style,
									'margin',
									$mdgriffith$elm_ui$Element$Input$renderBox(
										$mdgriffith$elm_ui$Element$Input$negateBox(parentPadding)))),
								$mdgriffith$elm_ui$Internal$Model$Attr(
								A2($elm$html$Html$Attributes$style, 'box-sizing', 'content-box'))
							]);
					}
				}(),
				_Utils_ap(
					_List_fromArray(
						[
							$mdgriffith$elm_ui$Element$Input$value(textOptions.hN),
							$mdgriffith$elm_ui$Internal$Model$Attr(
							$elm$html$Html$Events$onInput(textOptions.g2)),
							$mdgriffith$elm_ui$Element$Input$hiddenLabelAttribute(textOptions.q),
							$mdgriffith$elm_ui$Element$Input$spellcheck(textInput.ai),
							A2(
							$elm$core$Maybe$withDefault,
							$mdgriffith$elm_ui$Internal$Model$NoAttribute,
							A2($elm$core$Maybe$map, $mdgriffith$elm_ui$Element$Input$autofill, textInput.ab))
						]),
					redistributed.u)),
			$mdgriffith$elm_ui$Internal$Model$Unkeyed(_List_Nil));
		var wrappedInput = function () {
			var _v0 = textInput.B;
			if (_v0.$ === 1) {
				return A4(
					$mdgriffith$elm_ui$Internal$Model$element,
					$mdgriffith$elm_ui$Internal$Model$asEl,
					$mdgriffith$elm_ui$Internal$Model$div,
					_Utils_ap(
						(heightConstrained ? $elm$core$List$cons($mdgriffith$elm_ui$Element$scrollbarY) : $elm$core$Basics$identity)(
							_List_fromArray(
								[
									$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
									A2($elm$core$List$any, $mdgriffith$elm_ui$Element$Input$hasFocusStyle, withDefaults) ? $mdgriffith$elm_ui$Internal$Model$NoAttribute : $mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.eq),
									$mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.gO)
								])),
						redistributed.c),
					$mdgriffith$elm_ui$Internal$Model$Unkeyed(
						_List_fromArray(
							[
								A4(
								$mdgriffith$elm_ui$Internal$Model$element,
								$mdgriffith$elm_ui$Internal$Model$asParagraph,
								$mdgriffith$elm_ui$Internal$Model$div,
								A2(
									$elm$core$List$cons,
									$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
									A2(
										$elm$core$List$cons,
										$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
										A2(
											$elm$core$List$cons,
											$mdgriffith$elm_ui$Element$inFront(inputElement),
											A2(
												$elm$core$List$cons,
												$mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.gN),
												redistributed.br)))),
								$mdgriffith$elm_ui$Internal$Model$Unkeyed(
									function () {
										if (textOptions.hN === '') {
											var _v1 = textOptions.hd;
											if (_v1.$ === 1) {
												return _List_fromArray(
													[
														$mdgriffith$elm_ui$Element$text('\u00A0')
													]);
											} else {
												var place = _v1.a;
												return _List_fromArray(
													[
														A3($mdgriffith$elm_ui$Element$Input$renderPlaceholder, place, _List_Nil, textOptions.hN === '')
													]);
											}
										} else {
											return _List_fromArray(
												[
													$mdgriffith$elm_ui$Internal$Model$unstyled(
													A2(
														$elm$html$Html$span,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class($mdgriffith$elm_ui$Internal$Style$classes.gM)
															]),
														_List_fromArray(
															[
																$elm$html$Html$text(textOptions.hN + '\u00A0')
															])))
												]);
										}
									}()))
							])));
			} else {
				var inputType = _v0.a;
				return A4(
					$mdgriffith$elm_ui$Internal$Model$element,
					$mdgriffith$elm_ui$Internal$Model$asEl,
					$mdgriffith$elm_ui$Internal$Model$div,
					A2(
						$elm$core$List$cons,
						$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
						A2(
							$elm$core$List$cons,
							A2($elm$core$List$any, $mdgriffith$elm_ui$Element$Input$hasFocusStyle, withDefaults) ? $mdgriffith$elm_ui$Internal$Model$NoAttribute : $mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.eq),
							$elm$core$List$concat(
								_List_fromArray(
									[
										redistributed.c,
										function () {
										var _v2 = textOptions.hd;
										if (_v2.$ === 1) {
											return _List_Nil;
										} else {
											var place = _v2.a;
											return _List_fromArray(
												[
													$mdgriffith$elm_ui$Element$behindContent(
													A3($mdgriffith$elm_ui$Element$Input$renderPlaceholder, place, redistributed.L, textOptions.hN === ''))
												]);
										}
									}()
									])))),
					$mdgriffith$elm_ui$Internal$Model$Unkeyed(
						_List_fromArray(
							[inputElement])));
			}
		}();
		return A3(
			$mdgriffith$elm_ui$Element$Input$applyLabel,
			A2(
				$elm$core$List$cons,
				A2($mdgriffith$elm_ui$Internal$Model$Class, $mdgriffith$elm_ui$Internal$Flag$cursor, $mdgriffith$elm_ui$Internal$Style$classes.gj),
				A2(
					$elm$core$List$cons,
					$mdgriffith$elm_ui$Element$Input$isHiddenLabel(textOptions.q) ? $mdgriffith$elm_ui$Internal$Model$NoAttribute : $mdgriffith$elm_ui$Element$spacing(5),
					A2($elm$core$List$cons, $mdgriffith$elm_ui$Element$Region$announce, redistributed.m))),
			textOptions.q,
			wrappedInput);
	});
var $mdgriffith$elm_ui$Element$Input$multiline = F2(
	function (attrs, multi) {
		return A3(
			$mdgriffith$elm_ui$Element$Input$textHelper,
			{ab: $elm$core$Maybe$Nothing, ai: multi.hC, B: $mdgriffith$elm_ui$Element$Input$TextArea},
			attrs,
			{q: multi.q, g2: multi.g2, hd: multi.hd, hN: multi.hN});
	});
var $author$project$Main$multiline = F3(
	function (onChange, text, label) {
		return A2(
			$mdgriffith$elm_ui$Element$Input$multiline,
			_List_Nil,
			{
				q: A2(
					$mdgriffith$elm_ui$Element$Input$labelAbove,
					_List_Nil,
					$mdgriffith$elm_ui$Element$text(label)),
				g2: onChange,
				hd: $elm$core$Maybe$Nothing,
				hC: true,
				hN: text
			});
	});
var $author$project$Main$CreateTabHoverNote = function (a) {
	return {$: 23, a: a};
};
var $author$project$Main$CreateTabSelectNote = function (a) {
	return {$: 15, a: a};
};
var $author$project$Main$CreateTabStopHover = {$: 24};
var $author$project$Main$DiscoveryModeHoverNote = function (a) {
	return {$: 31, a: a};
};
var $author$project$Main$DiscoveryModeSelectNote = function (a) {
	return {$: 28, a: a};
};
var $author$project$Main$DiscoveryModeStopHover = {$: 32};
var $author$project$Main$EditModeHoverNote = function (a) {
	return {$: 39, a: a};
};
var $author$project$Main$EditModeSelectNoteOnGraph = function (a) {
	return {$: 36, a: a};
};
var $author$project$Main$EditModeStopHover = {$: 40};
var $mdgriffith$elm_ui$Internal$Model$Top = 0;
var $mdgriffith$elm_ui$Element$alignTop = $mdgriffith$elm_ui$Internal$Model$AlignY(0);
var $elm$svg$Svg$circle = $elm$svg$Svg$trustedNode('circle');
var $elm$svg$Svg$Attributes$cx = _VirtualDom_attribute('cx');
var $elm$svg$Svg$Attributes$cy = _VirtualDom_attribute('cy');
var $elm$svg$Svg$Attributes$r = _VirtualDom_attribute('r');
var $author$project$Main$svgCircle = F3(
	function (cx, cy, r) {
		return A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$r(r),
					$elm$svg$Svg$Attributes$fill('rgba(137, 196, 244, 1)'),
					$elm$svg$Svg$Attributes$cx(cx),
					$elm$svg$Svg$Attributes$cy(cy)
				]),
			_List_Nil);
	});
var $author$project$Main$svgLegend = function (contents) {
	return A2(
		$elm$svg$Svg$svg,
		_List_fromArray(
			[
				$elm$svg$Svg$Attributes$height('40'),
				$elm$svg$Svg$Attributes$width('40'),
				$elm$svg$Svg$Attributes$viewBox('0 0 40 40')
			]),
		contents);
};
var $author$project$Main$circleLegend = A2(
	$mdgriffith$elm_ui$Element$row,
	_List_Nil,
	_List_fromArray(
		[
			$mdgriffith$elm_ui$Element$html(
			$author$project$Main$svgLegend(
				_List_fromArray(
					[
						A3($author$project$Main$svgCircle, '20', '20', '10')
					]))),
			$mdgriffith$elm_ui$Element$text('Regular Note')
		]));
var $author$project$Main$PositionExtremes = F4(
	function (minX, minY, maxX, maxY) {
		return {eP: maxX, eQ: maxY, bb: minX, bc: minY};
	});
var $elm$core$Maybe$map4 = F5(
	function (func, ma, mb, mc, md) {
		if (ma.$ === 1) {
			return $elm$core$Maybe$Nothing;
		} else {
			var a = ma.a;
			if (mb.$ === 1) {
				return $elm$core$Maybe$Nothing;
			} else {
				var b = mb.a;
				if (mc.$ === 1) {
					return $elm$core$Maybe$Nothing;
				} else {
					var c = mc.a;
					if (md.$ === 1) {
						return $elm$core$Maybe$Nothing;
					} else {
						var d = md.a;
						return $elm$core$Maybe$Just(
							A4(func, a, b, c, d));
					}
				}
			}
		}
	});
var $author$project$Main$computeViewbox = function (notePositions) {
	var yList = A2(
		$elm$core$List$map,
		function ($) {
			return $.d0;
		},
		notePositions);
	var xList = A2(
		$elm$core$List$map,
		function ($) {
			return $.dZ;
		},
		notePositions);
	var padding = 50;
	var maybeExtremes = A5(
		$elm$core$Maybe$map4,
		$author$project$Main$PositionExtremes,
		$elm$core$List$minimum(xList),
		$elm$core$List$minimum(yList),
		$elm$core$List$maximum(xList),
		$elm$core$List$maximum(yList));
	var formatViewbox = function (record) {
		return $elm$core$String$fromFloat(record.bb) + (' ' + ($elm$core$String$fromFloat(record.bc) + (' ' + ($elm$core$String$fromFloat(record.aL) + (' ' + $elm$core$String$fromFloat(record.cO))))));
	};
	if (!maybeExtremes.$) {
		var extremes = maybeExtremes.a;
		return formatViewbox(
			{cO: (extremes.eQ - extremes.bc) + (padding * 2), bb: extremes.bb - padding, bc: extremes.bc - padding, aL: (extremes.eP - extremes.bb) + (padding * 2)});
	} else {
		return formatViewbox(
			{cO: 100, bb: 100, bc: 100, aL: 100});
	}
};
var $author$project$Main$svgRectTransform = F3(
	function (x, y, transform) {
		return A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$fill('rgb(0,0,0)'),
					$elm$svg$Svg$Attributes$width('20'),
					$elm$svg$Svg$Attributes$height('20'),
					$elm$svg$Svg$Attributes$x(x),
					$elm$svg$Svg$Attributes$y(y),
					$elm$svg$Svg$Attributes$transform(transform)
				]),
			_List_Nil);
	});
var $author$project$Main$svgRect = F2(
	function (x, y) {
		return A3($author$project$Main$svgRectTransform, x, y, '');
	});
var $author$project$Main$discussionLegend = A2(
	$mdgriffith$elm_ui$Element$row,
	_List_Nil,
	_List_fromArray(
		[
			$mdgriffith$elm_ui$Element$html(
			$author$project$Main$svgLegend(
				_List_fromArray(
					[
						A2($author$project$Main$svgRect, '10', '10')
					]))),
			$mdgriffith$elm_ui$Element$text('Discussion (if not selected)')
		]));
var $elm$svg$Svg$line = $elm$svg$Svg$trustedNode('line');
var $elm$svg$Svg$Attributes$stroke = _VirtualDom_attribute('stroke');
var $elm$svg$Svg$Attributes$strokeDasharray = _VirtualDom_attribute('stroke-dasharray');
var $elm$svg$Svg$Attributes$x1 = _VirtualDom_attribute('x1');
var $elm$svg$Svg$Attributes$x2 = _VirtualDom_attribute('x2');
var $elm$svg$Svg$Attributes$y1 = _VirtualDom_attribute('y1');
var $elm$svg$Svg$Attributes$y2 = _VirtualDom_attribute('y2');
var $author$project$Main$svgDashedLine = F4(
	function (x1, x2, y1, y2) {
		return A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1(x1),
					$elm$svg$Svg$Attributes$x2(x2),
					$elm$svg$Svg$Attributes$y1(y1),
					$elm$svg$Svg$Attributes$y2(y2),
					$elm$svg$Svg$Attributes$stroke('black'),
					$elm$svg$Svg$Attributes$strokeDasharray('5,5')
				]),
			_List_Nil);
	});
var $author$project$Main$linkBreakLegend = A2(
	$mdgriffith$elm_ui$Element$row,
	_List_Nil,
	_List_fromArray(
		[
			$mdgriffith$elm_ui$Element$html(
			$author$project$Main$svgLegend(
				_List_fromArray(
					[
						A4($author$project$Main$svgDashedLine, '10', '30', '20', '20')
					]))),
			$mdgriffith$elm_ui$Element$text('Link to Break')
		]));
var $author$project$Main$svgLine = F4(
	function (x1, x2, y1, y2) {
		return A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1(x1),
					$elm$svg$Svg$Attributes$x2(x2),
					$elm$svg$Svg$Attributes$y1(y1),
					$elm$svg$Svg$Attributes$y2(y2),
					$elm$svg$Svg$Attributes$stroke('black')
				]),
			_List_Nil);
	});
var $author$project$Main$linkedCircleLegend = A2(
	$mdgriffith$elm_ui$Element$row,
	_List_Nil,
	_List_fromArray(
		[
			$mdgriffith$elm_ui$Element$html(
			$author$project$Main$svgLegend(
				_List_fromArray(
					[
						A2(
						$elm$svg$Svg$g,
						_List_Nil,
						_List_fromArray(
							[
								A3($author$project$Main$svgCircle, '20', '20', '10'),
								A4($author$project$Main$svgLine, '10', '30', '20', '20'),
								A4($author$project$Main$svgLine, '20', '20', '10', '30')
							]))
					]))),
			$mdgriffith$elm_ui$Element$text('Note Marked to link (if not selected)')
		]));
var $author$project$Main$selectedNoteLegend = A2(
	$mdgriffith$elm_ui$Element$row,
	_List_Nil,
	_List_fromArray(
		[
			$mdgriffith$elm_ui$Element$html(
			$author$project$Main$svgLegend(
				_List_fromArray(
					[
						A2(
						$elm$svg$Svg$g,
						_List_Nil,
						_List_fromArray(
							[
								A2($author$project$Main$svgRect, '10', '10'),
								A3($author$project$Main$svgRectTransform, '10', '10', 'rotate(45 20 20)')
							]))
					]))),
			$mdgriffith$elm_ui$Element$text('Currently Selected Note')
		]));
var $elm$svg$Svg$Attributes$style = _VirtualDom_attribute('style');
var $author$project$Main$textWrap = function (text) {
	return A2(
		$mdgriffith$elm_ui$Element$paragraph,
		_List_Nil,
		_List_fromArray(
			[
				$mdgriffith$elm_ui$Element$text(text)
			]));
};
var $elm$core$Maybe$map2 = F3(
	function (func, ma, mb) {
		if (ma.$ === 1) {
			return $elm$core$Maybe$Nothing;
		} else {
			var a = ma.a;
			if (mb.$ === 1) {
				return $elm$core$Maybe$Nothing;
			} else {
				var b = mb.a;
				return $elm$core$Maybe$Just(
					A2(func, a, b));
			}
		}
	});
var $elm$svg$Svg$Attributes$strokeWidth = _VirtualDom_attribute('stroke-width');
var $author$project$Main$toCreateTabGraphLink = F2(
	function (notePositions, link) {
		var maybeGetNoteByIdentifier = function (identifier) {
			return $elm$core$List$head(
				A2(
					$elm$core$List$filter,
					function (notePosition) {
						return A2(identifier, link, notePosition.eW);
					},
					notePositions));
		};
		var line = F2(
			function (note1, note2) {
				return A2(
					$elm$svg$Svg$line,
					_List_fromArray(
						[
							$elm$svg$Svg$Attributes$x1(
							$elm$core$String$fromFloat(note1.dZ)),
							$elm$svg$Svg$Attributes$y1(
							$elm$core$String$fromFloat(note1.d0)),
							$elm$svg$Svg$Attributes$x2(
							$elm$core$String$fromFloat(note2.dZ)),
							$elm$svg$Svg$Attributes$y2(
							$elm$core$String$fromFloat(note2.d0)),
							$elm$svg$Svg$Attributes$stroke('rgb(0,0,0)'),
							$elm$svg$Svg$Attributes$strokeWidth('2')
						]),
					_List_Nil);
			});
		return A3(
			$elm$core$Maybe$map2,
			line,
			maybeGetNoteByIdentifier($author$project$Link$isSource),
			maybeGetNoteByIdentifier($author$project$Link$isTarget));
	});
var $author$project$Main$Discussion = F3(
	function (a, b, c) {
		return {$: 2, a: a, b: b, c: c};
	});
var $author$project$Main$Linked = F3(
	function (a, b, c) {
		return {$: 1, a: a, b: b, c: c};
	});
var $author$project$Main$Regular = F3(
	function (a, b, c) {
		return {$: 3, a: a, b: b, c: c};
	});
var $author$project$Main$Selected = F3(
	function (a, b, c) {
		return {$: 0, a: a, b: b, c: c};
	});
var $author$project$Main$toCreateTabGraphNote = F3(
	function (notesAssociatedToCreatedLinks, selectedNote, notePosition) {
		var y = $elm$core$String$fromFloat(notePosition.d0);
		var x = $elm$core$String$fromFloat(notePosition.dZ);
		var note = notePosition.eW;
		var isSelectedNote = A2($author$project$Note$is, note, selectedNote);
		var isDiscussion = $author$project$Note$getVariant(note) === 1;
		var hasCreatedLink = A2(
			$elm$core$List$any,
			$author$project$Note$is(note),
			notesAssociatedToCreatedLinks);
		if (isSelectedNote) {
			return A3($author$project$Main$Selected, note, x, y);
		} else {
			if (isDiscussion) {
				return A3($author$project$Main$Discussion, note, x, y);
			} else {
				if (hasCreatedLink) {
					return A3($author$project$Main$Linked, note, x, y);
				} else {
					return A3($author$project$Main$Regular, note, x, y);
				}
			}
		}
	});
var $author$project$Main$toGraphLinkDeleteLink = F3(
	function (notePositions, linkToDelete, link) {
		var maybeGetNoteByIdentifier = function (identifier) {
			return $elm$core$List$head(
				A2(
					$elm$core$List$filter,
					function (notePosition) {
						return A2(identifier, link, notePosition.eW);
					},
					notePositions));
		};
		var line = F2(
			function (note1, note2) {
				return A2($author$project$Link$is, linkToDelete, link) ? A2(
					$elm$svg$Svg$line,
					_List_fromArray(
						[
							$elm$svg$Svg$Attributes$x1(
							$elm$core$String$fromFloat(note1.dZ)),
							$elm$svg$Svg$Attributes$y1(
							$elm$core$String$fromFloat(note1.d0)),
							$elm$svg$Svg$Attributes$x2(
							$elm$core$String$fromFloat(note2.dZ)),
							$elm$svg$Svg$Attributes$y2(
							$elm$core$String$fromFloat(note2.d0)),
							$elm$svg$Svg$Attributes$stroke('rgb(0,0,0)'),
							$elm$svg$Svg$Attributes$strokeWidth('2'),
							$elm$svg$Svg$Attributes$strokeDasharray('5,5')
						]),
					_List_Nil) : A2(
					$elm$svg$Svg$line,
					_List_fromArray(
						[
							$elm$svg$Svg$Attributes$x1(
							$elm$core$String$fromFloat(note1.dZ)),
							$elm$svg$Svg$Attributes$y1(
							$elm$core$String$fromFloat(note1.d0)),
							$elm$svg$Svg$Attributes$x2(
							$elm$core$String$fromFloat(note2.dZ)),
							$elm$svg$Svg$Attributes$y2(
							$elm$core$String$fromFloat(note2.d0)),
							$elm$svg$Svg$Attributes$stroke('rgb(0,0,0)'),
							$elm$svg$Svg$Attributes$strokeWidth('2')
						]),
					_List_Nil);
			});
		return A3(
			$elm$core$Maybe$map2,
			line,
			maybeGetNoteByIdentifier($author$project$Link$isSource),
			maybeGetNoteByIdentifier($author$project$Link$isTarget));
	});
var $elm$svg$Svg$Attributes$cursor = _VirtualDom_attribute('cursor');
var $elm$svg$Svg$Events$onClick = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'click',
		$elm$json$Json$Decode$succeed(msg));
};
var $elm$svg$Svg$Events$onMouseOut = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'mouseout',
		$elm$json$Json$Decode$succeed(msg));
};
var $elm$svg$Svg$Events$onMouseOver = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'mouseover',
		$elm$json$Json$Decode$succeed(msg));
};
var $elm$core$String$toFloat = _String_toFloat;
var $author$project$Main$viewGraphNote = F4(
	function (onClick, mouseOver, mouseOut, graphNote) {
		var gLambda = F2(
			function (note, content) {
				return A2(
					$elm$svg$Svg$g,
					_List_fromArray(
						[
							$elm$svg$Svg$Attributes$cursor('Pointer'),
							$elm$svg$Svg$Events$onClick(
							onClick(note)),
							$elm$svg$Svg$Events$onMouseOver(
							mouseOver(note)),
							$elm$svg$Svg$Events$onMouseOut(mouseOut)
						]),
					content);
			});
		switch (graphNote.$) {
			case 0:
				var note = graphNote.a;
				var x = graphNote.b;
				var y = graphNote.c;
				var transformation = 'rotate(45 ' + (x + (' ' + (y + ')')));
				var center = function (str) {
					var _v1 = $elm$core$String$toFloat(str);
					if (!_v1.$) {
						var s = _v1.a;
						return $elm$core$String$fromFloat(s - 10);
					} else {
						return str;
					}
				};
				var xCenter = center(x);
				var yCenter = center(y);
				return A2(
					gLambda,
					note,
					_List_fromArray(
						[
							A2($author$project$Main$svgRect, xCenter, yCenter),
							A3($author$project$Main$svgRectTransform, xCenter, yCenter, transformation)
						]));
			case 1:
				var note = graphNote.a;
				var x = graphNote.b;
				var y = graphNote.c;
				var modify = F2(
					function (str, increment) {
						var _v2 = $elm$core$String$toFloat(str);
						if (!_v2.$) {
							var s = _v2.a;
							return $elm$core$String$fromFloat(s + increment);
						} else {
							return str;
						}
					});
				return A2(
					gLambda,
					note,
					_List_fromArray(
						[
							A3($author$project$Main$svgCircle, x, y, '5'),
							A4(
							$author$project$Main$svgLine,
							A2(modify, x, -5),
							A2(modify, x, 5),
							y,
							y),
							A4(
							$author$project$Main$svgLine,
							x,
							x,
							A2(modify, y, -5),
							A2(modify, y, 5))
						]));
			case 2:
				var note = graphNote.a;
				var x = graphNote.b;
				var y = graphNote.c;
				var center = function (str) {
					var _v3 = $elm$core$String$toFloat(str);
					if (!_v3.$) {
						var s = _v3.a;
						return $elm$core$String$fromFloat(s - 10);
					} else {
						return str;
					}
				};
				var xCenter = center(x);
				var yCenter = center(y);
				return A2(
					gLambda,
					note,
					_List_fromArray(
						[
							A2($author$project$Main$svgRect, xCenter, yCenter)
						]));
			default:
				var note = graphNote.a;
				var x = graphNote.b;
				var y = graphNote.c;
				return A2(
					gLambda,
					note,
					_List_fromArray(
						[
							A3($author$project$Main$svgCircle, x, y, '5')
						]));
		}
	});
var $mdgriffith$elm_ui$Internal$Model$Padding = F5(
	function (a, b, c, d, e) {
		return {$: 0, a: a, b: b, c: c, d: d, e: e};
	});
var $mdgriffith$elm_ui$Internal$Model$Spaced = F3(
	function (a, b, c) {
		return {$: 0, a: a, b: b, c: c};
	});
var $mdgriffith$elm_ui$Internal$Model$extractSpacingAndPadding = function (attrs) {
	return A3(
		$elm$core$List$foldr,
		F2(
			function (attr, _v0) {
				var pad = _v0.a;
				var spacing = _v0.b;
				return _Utils_Tuple2(
					function () {
						if (!pad.$) {
							var x = pad.a;
							return pad;
						} else {
							if ((attr.$ === 4) && (attr.b.$ === 7)) {
								var _v3 = attr.b;
								var name = _v3.a;
								var t = _v3.b;
								var r = _v3.c;
								var b = _v3.d;
								var l = _v3.e;
								return $elm$core$Maybe$Just(
									A5($mdgriffith$elm_ui$Internal$Model$Padding, name, t, r, b, l));
							} else {
								return $elm$core$Maybe$Nothing;
							}
						}
					}(),
					function () {
						if (!spacing.$) {
							var x = spacing.a;
							return spacing;
						} else {
							if ((attr.$ === 4) && (attr.b.$ === 5)) {
								var _v6 = attr.b;
								var name = _v6.a;
								var x = _v6.b;
								var y = _v6.c;
								return $elm$core$Maybe$Just(
									A3($mdgriffith$elm_ui$Internal$Model$Spaced, name, x, y));
							} else {
								return $elm$core$Maybe$Nothing;
							}
						}
					}());
			}),
		_Utils_Tuple2($elm$core$Maybe$Nothing, $elm$core$Maybe$Nothing),
		attrs);
};
var $mdgriffith$elm_ui$Element$wrappedRow = F2(
	function (attrs, children) {
		var _v0 = $mdgriffith$elm_ui$Internal$Model$extractSpacingAndPadding(attrs);
		var padded = _v0.a;
		var spaced = _v0.b;
		if (spaced.$ === 1) {
			return A4(
				$mdgriffith$elm_ui$Internal$Model$element,
				$mdgriffith$elm_ui$Internal$Model$asRow,
				$mdgriffith$elm_ui$Internal$Model$div,
				A2(
					$elm$core$List$cons,
					$mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.bv + (' ' + ($mdgriffith$elm_ui$Internal$Style$classes.aw + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.dY)))),
					A2(
						$elm$core$List$cons,
						$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$shrink),
						A2(
							$elm$core$List$cons,
							$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$shrink),
							attrs))),
				$mdgriffith$elm_ui$Internal$Model$Unkeyed(children));
		} else {
			var _v2 = spaced.a;
			var spaceName = _v2.a;
			var x = _v2.b;
			var y = _v2.c;
			var newPadding = function () {
				if (!padded.$) {
					var _v5 = padded.a;
					var name = _v5.a;
					var t = _v5.b;
					var r = _v5.c;
					var b = _v5.d;
					var l = _v5.e;
					if ((_Utils_cmp(r, x / 2) > -1) && (_Utils_cmp(b, y / 2) > -1)) {
						var newTop = t - (y / 2);
						var newRight = r - (x / 2);
						var newLeft = l - (x / 2);
						var newBottom = b - (y / 2);
						return $elm$core$Maybe$Just(
							A2(
								$mdgriffith$elm_ui$Internal$Model$StyleClass,
								$mdgriffith$elm_ui$Internal$Flag$padding,
								A5(
									$mdgriffith$elm_ui$Internal$Model$PaddingStyle,
									A4($mdgriffith$elm_ui$Internal$Model$paddingNameFloat, newTop, newRight, newBottom, newLeft),
									newTop,
									newRight,
									newBottom,
									newLeft)));
					} else {
						return $elm$core$Maybe$Nothing;
					}
				} else {
					return $elm$core$Maybe$Nothing;
				}
			}();
			if (!newPadding.$) {
				var pad = newPadding.a;
				return A4(
					$mdgriffith$elm_ui$Internal$Model$element,
					$mdgriffith$elm_ui$Internal$Model$asRow,
					$mdgriffith$elm_ui$Internal$Model$div,
					A2(
						$elm$core$List$cons,
						$mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.bv + (' ' + ($mdgriffith$elm_ui$Internal$Style$classes.aw + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.dY)))),
						A2(
							$elm$core$List$cons,
							$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$shrink),
							A2(
								$elm$core$List$cons,
								$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$shrink),
								_Utils_ap(
									attrs,
									_List_fromArray(
										[pad]))))),
					$mdgriffith$elm_ui$Internal$Model$Unkeyed(children));
			} else {
				var halfY = -(y / 2);
				var halfX = -(x / 2);
				return A4(
					$mdgriffith$elm_ui$Internal$Model$element,
					$mdgriffith$elm_ui$Internal$Model$asEl,
					$mdgriffith$elm_ui$Internal$Model$div,
					attrs,
					$mdgriffith$elm_ui$Internal$Model$Unkeyed(
						_List_fromArray(
							[
								A4(
								$mdgriffith$elm_ui$Internal$Model$element,
								$mdgriffith$elm_ui$Internal$Model$asRow,
								$mdgriffith$elm_ui$Internal$Model$div,
								A2(
									$elm$core$List$cons,
									$mdgriffith$elm_ui$Internal$Model$htmlClass($mdgriffith$elm_ui$Internal$Style$classes.bv + (' ' + ($mdgriffith$elm_ui$Internal$Style$classes.aw + (' ' + $mdgriffith$elm_ui$Internal$Style$classes.dY)))),
									A2(
										$elm$core$List$cons,
										$mdgriffith$elm_ui$Internal$Model$Attr(
											A2(
												$elm$html$Html$Attributes$style,
												'margin',
												$elm$core$String$fromFloat(halfY) + ('px' + (' ' + ($elm$core$String$fromFloat(halfX) + 'px'))))),
										A2(
											$elm$core$List$cons,
											$mdgriffith$elm_ui$Internal$Model$Attr(
												A2(
													$elm$html$Html$Attributes$style,
													'width',
													'calc(100% + ' + ($elm$core$String$fromInt(x) + 'px)'))),
											A2(
												$elm$core$List$cons,
												$mdgriffith$elm_ui$Internal$Model$Attr(
													A2(
														$elm$html$Html$Attributes$style,
														'height',
														'calc(100% + ' + ($elm$core$String$fromInt(y) + 'px)'))),
												A2(
													$elm$core$List$cons,
													A2(
														$mdgriffith$elm_ui$Internal$Model$StyleClass,
														$mdgriffith$elm_ui$Internal$Flag$spacing,
														A3($mdgriffith$elm_ui$Internal$Model$SpacingStyle, spaceName, x, y)),
													_List_Nil))))),
								$mdgriffith$elm_ui$Internal$Model$Unkeyed(children))
							])));
			}
		}
	});
var $author$project$Main$svgGraph = F4(
	function (graph, tab, selectedNote, maybeHoverNote) {
		var notesLambda = F4(
			function (onSelect, onMouseOver, onMouseOut, linkedNotes) {
				return A2(
					$elm$core$List$map,
					function (n) {
						return A4($author$project$Main$viewGraphNote, onSelect, onMouseOver, onMouseOut, n);
					},
					A2(
						$elm$core$List$map,
						A2($author$project$Main$toCreateTabGraphNote, linkedNotes, selectedNote),
						graph.hf));
			});
		var linkLambda = function (filterMap) {
			return A2($elm$core$List$filterMap, filterMap, graph.gT);
		};
		var legend = A2(
			$mdgriffith$elm_ui$Element$el,
			_List_fromArray(
				[$mdgriffith$elm_ui$Element$alignBottom]),
			A2(
				$mdgriffith$elm_ui$Element$wrappedRow,
				_List_Nil,
				_List_fromArray(
					[$author$project$Main$selectedNoteLegend, $author$project$Main$linkedCircleLegend, $author$project$Main$discussionLegend, $author$project$Main$circleLegend, $author$project$Main$linkBreakLegend])));
		var hover = function () {
			if (!maybeHoverNote.$) {
				var hoverNote = maybeHoverNote.a;
				return A2(
					$mdgriffith$elm_ui$Element$el,
					_List_fromArray(
						[
							$mdgriffith$elm_ui$Element$alignTop,
							$mdgriffith$elm_ui$Element$alignLeft,
							$mdgriffith$elm_ui$Element$padding(8)
						]),
					$author$project$Main$textWrap(
						$author$project$Note$getContent(hoverNote)));
			} else {
				return $mdgriffith$elm_ui$Element$none;
			}
		}();
		var _v0 = function () {
			switch (tab.$) {
				case 0:
					var link = tab.a;
					return _Utils_Tuple2(
						linkLambda(
							A2($author$project$Main$toGraphLinkDeleteLink, graph.hf, link)),
						A4(notesLambda, $author$project$Main$EditModeSelectNoteOnGraph, $author$project$Main$EditModeHoverNote, $author$project$Main$EditModeStopHover, _List_Nil));
				case 1:
					var newlyLinkedNotes = tab.a;
					return _Utils_Tuple2(
						linkLambda(
							$author$project$Main$toCreateTabGraphLink(graph.hf)),
						A4(notesLambda, $author$project$Main$CreateTabSelectNote, $author$project$Main$CreateTabHoverNote, $author$project$Main$CreateTabStopHover, newlyLinkedNotes));
				default:
					return _Utils_Tuple2(
						linkLambda(
							$author$project$Main$toCreateTabGraphLink(graph.hf)),
						A4(notesLambda, $author$project$Main$DiscoveryModeSelectNote, $author$project$Main$DiscoveryModeHoverNote, $author$project$Main$DiscoveryModeStopHover, _List_Nil));
			}
		}();
		var links = _v0.a;
		var notes = _v0.b;
		return A2(
			$mdgriffith$elm_ui$Element$el,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$width($author$project$Main$biggerElement),
					$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
					$mdgriffith$elm_ui$Element$htmlAttribute(
					A2($elm$html$Html$Attributes$style, 'position', 'relative'))
				]),
			A2(
				$mdgriffith$elm_ui$Element$el,
				_List_fromArray(
					[
						$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
						$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
						$mdgriffith$elm_ui$Element$inFront(legend),
						$mdgriffith$elm_ui$Element$inFront(hover)
					]),
				$mdgriffith$elm_ui$Element$html(
					A2(
						$elm$svg$Svg$svg,
						_List_fromArray(
							[
								$elm$svg$Svg$Attributes$width('100%'),
								$elm$svg$Svg$Attributes$height('100%'),
								$elm$svg$Svg$Attributes$viewBox(
								$author$project$Main$computeViewbox(graph.hf)),
								$elm$svg$Svg$Attributes$style('position: absolute')
							]),
						$elm$core$List$concat(
							_List_fromArray(
								[links, notes]))))));
	});
var $mdgriffith$elm_ui$Element$InternalColumn = function (a) {
	return {$: 1, a: a};
};
var $mdgriffith$elm_ui$Internal$Model$GridPosition = function (a) {
	return {$: 9, a: a};
};
var $mdgriffith$elm_ui$Internal$Model$GridTemplateStyle = function (a) {
	return {$: 8, a: a};
};
var $elm$core$List$all = F2(
	function (isOkay, list) {
		return !A2(
			$elm$core$List$any,
			A2($elm$core$Basics$composeL, $elm$core$Basics$not, isOkay),
			list);
	});
var $mdgriffith$elm_ui$Internal$Model$AsGrid = 3;
var $mdgriffith$elm_ui$Internal$Model$asGrid = 3;
var $mdgriffith$elm_ui$Internal$Model$getSpacing = F2(
	function (attrs, _default) {
		return A2(
			$elm$core$Maybe$withDefault,
			_default,
			A3(
				$elm$core$List$foldr,
				F2(
					function (attr, acc) {
						if (!acc.$) {
							var x = acc.a;
							return $elm$core$Maybe$Just(x);
						} else {
							if ((attr.$ === 4) && (attr.b.$ === 5)) {
								var _v2 = attr.b;
								var x = _v2.b;
								var y = _v2.c;
								return $elm$core$Maybe$Just(
									_Utils_Tuple2(x, y));
							} else {
								return $elm$core$Maybe$Nothing;
							}
						}
					}),
				$elm$core$Maybe$Nothing,
				attrs));
	});
var $mdgriffith$elm_ui$Internal$Flag$gridPosition = $mdgriffith$elm_ui$Internal$Flag$flag(35);
var $mdgriffith$elm_ui$Internal$Flag$gridTemplate = $mdgriffith$elm_ui$Internal$Flag$flag(34);
var $elm$core$List$repeatHelp = F3(
	function (result, n, value) {
		repeatHelp:
		while (true) {
			if (n <= 0) {
				return result;
			} else {
				var $temp$result = A2($elm$core$List$cons, value, result),
					$temp$n = n - 1,
					$temp$value = value;
				result = $temp$result;
				n = $temp$n;
				value = $temp$value;
				continue repeatHelp;
			}
		}
	});
var $elm$core$List$repeat = F2(
	function (n, value) {
		return A3($elm$core$List$repeatHelp, _List_Nil, n, value);
	});
var $mdgriffith$elm_ui$Element$tableHelper = F2(
	function (attrs, config) {
		var onGrid = F3(
			function (rowLevel, columnLevel, elem) {
				return A4(
					$mdgriffith$elm_ui$Internal$Model$element,
					$mdgriffith$elm_ui$Internal$Model$asEl,
					$mdgriffith$elm_ui$Internal$Model$div,
					_List_fromArray(
						[
							A2(
							$mdgriffith$elm_ui$Internal$Model$StyleClass,
							$mdgriffith$elm_ui$Internal$Flag$gridPosition,
							$mdgriffith$elm_ui$Internal$Model$GridPosition(
								{ef: columnLevel, cO: 1, fh: rowLevel, aL: 1}))
						]),
					$mdgriffith$elm_ui$Internal$Model$Unkeyed(
						_List_fromArray(
							[elem])));
			});
		var columnWidth = function (col) {
			if (!col.$) {
				var colConfig = col.a;
				return colConfig.aL;
			} else {
				var colConfig = col.a;
				return colConfig.aL;
			}
		};
		var columnHeader = function (col) {
			if (!col.$) {
				var colConfig = col.a;
				return colConfig.bD;
			} else {
				var colConfig = col.a;
				return colConfig.bD;
			}
		};
		var maybeHeaders = function (headers) {
			return A2(
				$elm$core$List$all,
				$elm$core$Basics$eq($mdgriffith$elm_ui$Internal$Model$Empty),
				headers) ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(
				A2(
					$elm$core$List$indexedMap,
					F2(
						function (col, header) {
							return A3(onGrid, 1, col + 1, header);
						}),
					headers));
		}(
			A2($elm$core$List$map, columnHeader, config.b2));
		var add = F3(
			function (cell, columnConfig, cursor) {
				if (!columnConfig.$) {
					var col = columnConfig.a;
					return _Utils_update(
						cursor,
						{
							av: cursor.av + 1,
							aj: A2(
								$elm$core$List$cons,
								A3(
									onGrid,
									cursor.fh,
									cursor.av,
									A2(
										col.bq,
										_Utils_eq(maybeHeaders, $elm$core$Maybe$Nothing) ? (cursor.fh - 1) : (cursor.fh - 2),
										cell)),
								cursor.aj)
						});
				} else {
					var col = columnConfig.a;
					return {
						av: cursor.av + 1,
						aj: A2(
							$elm$core$List$cons,
							A3(
								onGrid,
								cursor.fh,
								cursor.av,
								col.bq(cell)),
							cursor.aj),
						fh: cursor.fh
					};
				}
			});
		var build = F3(
			function (columns, rowData, cursor) {
				var newCursor = A3(
					$elm$core$List$foldl,
					add(rowData),
					cursor,
					columns);
				return {av: 1, aj: newCursor.aj, fh: cursor.fh + 1};
			});
		var children = A3(
			$elm$core$List$foldl,
			build(config.b2),
			{
				av: 1,
				aj: _List_Nil,
				fh: _Utils_eq(maybeHeaders, $elm$core$Maybe$Nothing) ? 1 : 2
			},
			config.b7);
		var _v0 = A2(
			$mdgriffith$elm_ui$Internal$Model$getSpacing,
			attrs,
			_Utils_Tuple2(0, 0));
		var sX = _v0.a;
		var sY = _v0.b;
		var template = A2(
			$mdgriffith$elm_ui$Internal$Model$StyleClass,
			$mdgriffith$elm_ui$Internal$Flag$gridTemplate,
			$mdgriffith$elm_ui$Internal$Model$GridTemplateStyle(
				{
					b2: A2($elm$core$List$map, columnWidth, config.b2),
					hn: A2(
						$elm$core$List$repeat,
						$elm$core$List$length(config.b7),
						$mdgriffith$elm_ui$Internal$Model$Content),
					hB: _Utils_Tuple2(
						$mdgriffith$elm_ui$Element$px(sX),
						$mdgriffith$elm_ui$Element$px(sY))
				}));
		return A4(
			$mdgriffith$elm_ui$Internal$Model$element,
			$mdgriffith$elm_ui$Internal$Model$asGrid,
			$mdgriffith$elm_ui$Internal$Model$div,
			A2(
				$elm$core$List$cons,
				$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
				A2($elm$core$List$cons, template, attrs)),
			$mdgriffith$elm_ui$Internal$Model$Unkeyed(
				function () {
					if (maybeHeaders.$ === 1) {
						return children.aj;
					} else {
						var renderedHeaders = maybeHeaders.a;
						return _Utils_ap(
							renderedHeaders,
							$elm$core$List$reverse(children.aj));
					}
				}()));
	});
var $mdgriffith$elm_ui$Element$table = F2(
	function (attrs, config) {
		return A2(
			$mdgriffith$elm_ui$Element$tableHelper,
			attrs,
			{
				b2: A2($elm$core$List$map, $mdgriffith$elm_ui$Element$InternalColumn, config.b2),
				b7: config.b7
			});
	});
var $mdgriffith$elm_ui$Internal$Model$AsTextColumn = 5;
var $mdgriffith$elm_ui$Internal$Model$asTextColumn = 5;
var $mdgriffith$elm_ui$Element$textColumn = F2(
	function (attrs, children) {
		return A4(
			$mdgriffith$elm_ui$Internal$Model$element,
			$mdgriffith$elm_ui$Internal$Model$asTextColumn,
			$mdgriffith$elm_ui$Internal$Model$div,
			A2(
				$elm$core$List$cons,
				$mdgriffith$elm_ui$Element$width(
					A2(
						$mdgriffith$elm_ui$Element$maximum,
						750,
						A2($mdgriffith$elm_ui$Element$minimum, 500, $mdgriffith$elm_ui$Element$fill))),
				attrs),
			$mdgriffith$elm_ui$Internal$Model$Unkeyed(children));
	});
var $author$project$SourceTitle$titlesAreDifferent = function (title) {
	return function (t) {
		return !_Utils_eq(
			$elm$core$String$toLower(t),
			$elm$core$String$toLower(title));
	};
};
var $author$project$SourceTitle$allExistingTitlesAreDifferent = F2(
	function (existingTitles, title) {
		return A2(
			$elm$core$List$all,
			$author$project$SourceTitle$titlesAreDifferent(title),
			existingTitles);
	});
var $author$project$SourceTitle$validateNewSourceTitle = F2(
	function (existingTitles, title) {
		return $author$project$SourceTitle$isValid(title) && A2($author$project$SourceTitle$allExistingTitlesAreDifferent, existingTitles, title);
	});
var $author$project$Create$ChooseDiscussionView = F4(
	function (a, b, c, d) {
		return {$: 1, a: a, b: b, c: c, d: d};
	});
var $author$project$Create$ChooseSourceCategoryView = F2(
	function (a, b) {
		return {$: 4, a: a, b: b};
	});
var $author$project$Create$CreateNewSourceView = F4(
	function (a, b, c, d) {
		return {$: 5, a: a, b: b, c: c, d: d};
	});
var $author$project$Create$DesignateDiscussionEntryPointView = F2(
	function (a, b) {
		return {$: 3, a: a, b: b};
	});
var $author$project$Create$DiscussionChosenView = F7(
	function (a, b, c, d, e, f, g) {
		return {$: 2, a: a, b: b, c: c, d: d, e: e, f: f, g: g};
	});
var $author$project$Create$NoteInputView = F3(
	function (a, b, c) {
		return {$: 0, a: a, b: b, c: c};
	});
var $author$project$Create$PromptCreateAnotherView = function (a) {
	return {$: 6, a: a};
};
var $author$project$Create$getQuestionsRead = function (internal) {
	var questionsRead = internal.b;
	return questionsRead;
};
var $author$project$Create$isOpen = function (modal) {
	if (!modal) {
		return true;
	} else {
		return false;
	}
};
var $author$project$Create$view = function (create) {
	switch (create.$) {
		case 0:
			var coachingModal = create.a;
			var createModeInternal = create.b;
			var note = $author$project$Create$getNote(createModeInternal);
			var canContinue = !$elm$core$String$isEmpty(note);
			return A3(
				$author$project$Create$NoteInputView,
				$author$project$Create$isOpen(coachingModal),
				canContinue,
				note);
		case 1:
			var coachingModal = create.a;
			var createModeInternal = create.b;
			var note = $author$project$Create$getNote(createModeInternal);
			var canContinue = $elm$core$List$isEmpty(
				$author$project$Create$getCreatedLinks(createModeInternal));
			return A4(
				$author$project$Create$ChooseDiscussionView,
				$author$project$Create$isOpen(coachingModal),
				canContinue,
				note,
				$author$project$Create$getQuestionsRead(createModeInternal));
		case 2:
			var graph = create.b;
			var createModeInternal = create.c;
			var question = create.d;
			var selectedNote = create.e;
			var hoveredNote = create.f;
			var note = $author$project$Create$getNote(createModeInternal);
			var createdLinks = $author$project$Create$getCreatedLinks(createModeInternal);
			var notesAssociatedToCreatedLinks = A2($elm$core$List$map, $author$project$Create$getNoteOnLink, createdLinks);
			var selectedNoteIsLinked = A2(
				$elm$core$List$any,
				$author$project$Create$linkIsForNote(selectedNote),
				createdLinks);
			return A7($author$project$Create$DiscussionChosenView, graph, note, question, selectedNote, selectedNoteIsLinked, notesAssociatedToCreatedLinks, hoveredNote);
		case 3:
			var createModeInternal = create.b;
			var string = create.c;
			return A2(
				$author$project$Create$DesignateDiscussionEntryPointView,
				$author$project$Create$getNote(createModeInternal),
				string);
		case 4:
			var createModeInternal = create.b;
			var string = create.c;
			return A2(
				$author$project$Create$ChooseSourceCategoryView,
				$author$project$Create$getNote(createModeInternal),
				string);
		case 5:
			var createModeInternal = create.b;
			var title = create.c;
			var author = create.d;
			var content = create.e;
			return A4(
				$author$project$Create$CreateNewSourceView,
				$author$project$Create$getNote(createModeInternal),
				title,
				author,
				content);
		default:
			var createModeInternal = create.a;
			return $author$project$Create$PromptCreateAnotherView(
				$author$project$Create$getNote(createModeInternal));
	}
};
var $author$project$Discovery$ChooseDiscussionView = function (a) {
	return {$: 1, a: a};
};
var $author$project$Discovery$DesignateDiscussionEntryPointView = F2(
	function (a, b) {
		return {$: 2, a: a, b: b};
	});
var $author$project$Discovery$ViewDiscussionView = F4(
	function (a, b, c, d) {
		return {$: 0, a: a, b: b, c: c, d: d};
	});
var $author$project$Discovery$view = function (discovery) {
	switch (discovery.$) {
		case 0:
			var discussion = discovery.a;
			var selectedNote = discovery.b;
			var graph = discovery.c;
			var hoverNote = discovery.d;
			return A4($author$project$Discovery$ViewDiscussionView, discussion, selectedNote, graph, hoverNote);
		case 1:
			var filterInput = discovery.a;
			return $author$project$Discovery$ChooseDiscussionView(filterInput);
		default:
			var selectedNote = discovery.a;
			var discussionInput = discovery.b;
			return A2(
				$author$project$Discovery$DesignateDiscussionEntryPointView,
				$author$project$Note$getContent(selectedNote),
				discussionInput);
	}
};
var $author$project$Edit$AddLinkChooseDiscussionView = {$: 4};
var $author$project$Edit$AddLinkDiscussionChosenView = {$: 5};
var $author$project$Edit$ViewConfirmBreakLink = F4(
	function (a, b, c, d) {
		return {$: 3, a: a, b: b, c: c, d: d};
	});
var $author$project$Edit$ViewDiscussionSelected = F2(
	function (a, b) {
		return {$: 2, a: a, b: b};
	});
var $author$project$Edit$ViewNoteSelected = F4(
	function (a, b, c, d) {
		return {$: 1, a: a, b: b, c: c, d: d};
	});
var $author$project$Edit$ViewSelectNote = function (a) {
	return {$: 0, a: a};
};
var $author$project$Edit$view = F2(
	function (slipbox, edit) {
		switch (edit.$) {
			case 0:
				var filter = edit.a;
				return $author$project$Edit$ViewSelectNote(filter);
			case 1:
				var note = edit.a;
				var source = function () {
					var _v3 = $author$project$SourceTitle$getTitle(
						$author$project$Note$getSource(note));
					if (_v3.$ === 1) {
						return $elm$core$Maybe$Nothing;
					} else {
						var sourceTitle = _v3.a;
						return $elm$core$List$head(
							A2(
								$author$project$Slipbox$getSources,
								$elm$core$Maybe$Just(sourceTitle),
								slipbox));
					}
				}();
				var linkedNodes = A2($author$project$Slipbox$getLinkedNotes, note, slipbox);
				var linkedNotes = A2(
					$elm$core$List$filter,
					function (_v2) {
						var n = _v2.a;
						return !$author$project$Note$getVariant(n);
					},
					linkedNodes);
				var linkedDiscussions = A2(
					$elm$core$List$filter,
					function (_v1) {
						var n = _v1.a;
						return $author$project$Note$getVariant(n) === 1;
					},
					linkedNodes);
				var lambda = function (list) {
					return $elm$core$List$isEmpty(list) ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(list);
				};
				return A4(
					$author$project$Edit$ViewNoteSelected,
					note,
					source,
					lambda(linkedDiscussions),
					lambda(linkedNotes));
			case 2:
				var discussion = edit.a;
				var linkedNodes = A2($author$project$Slipbox$getLinkedNotes, discussion, slipbox);
				var linkedNotes = A2(
					$elm$core$List$filter,
					function (_v4) {
						var n = _v4.a;
						return !$author$project$Note$getVariant(n);
					},
					linkedNodes);
				var lambda = function (list) {
					return $elm$core$List$isEmpty(list) ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(list);
				};
				return A2(
					$author$project$Edit$ViewDiscussionSelected,
					discussion,
					lambda(linkedNotes));
			case 3:
				var link = edit.b;
				var graph = edit.c;
				var selectedNote = edit.d;
				var hoveredNote = edit.e;
				return A4($author$project$Edit$ViewConfirmBreakLink, link, graph, selectedNote, hoveredNote);
			case 4:
				var filter = edit.a;
				var note = edit.b;
				var createdLinks = edit.c;
				return $author$project$Edit$AddLinkChooseDiscussionView;
			default:
				var previousNoteSelected = edit.a;
				var discussion = edit.b;
				var graph = edit.c;
				var selectedNote = edit.d;
				var hoveredNote = edit.e;
				var createdLinks = edit.f;
				return $author$project$Edit$AddLinkDiscussionChosenView;
		}
	});
var $author$project$Export$ConfigureContentView = F2(
	function (a, b) {
		return {$: 3, a: a, b: b};
	});
var $author$project$Export$ErrorStateNoDiscussionsView = {$: 0};
var $author$project$Export$InputProjectTitleView = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $author$project$Export$PromptAnotherExportView = {$: 4};
var $author$project$Export$SelectDiscussionsView = F5(
	function (a, b, c, d, e) {
		return {$: 2, a: a, b: b, c: c, d: d, e: e};
	});
var $author$project$Export$view = function (_export) {
	switch (_export.$) {
		case 0:
			return $author$project$Export$ErrorStateNoDiscussionsView;
		case 1:
			var projectTitle = _export.a;
			return A2(
				$author$project$Export$InputProjectTitleView,
				projectTitle,
				!$elm$core$String$isEmpty(projectTitle));
		case 2:
			var projectTitle = _export.a;
			var filter = _export.b;
			var discussions = _export.c;
			return A5(
				$author$project$Export$SelectDiscussionsView,
				projectTitle,
				filter,
				A2(
					$elm$core$List$map,
					$author$project$Export$getNote,
					A2($elm$core$List$filter, $author$project$Export$isSelected, discussions)),
				A2(
					$elm$core$List$map,
					$author$project$Export$getNote,
					A2(
						$elm$core$List$filter,
						function (d) {
							return A2(
								$author$project$Note$contains,
								filter,
								$author$project$Export$getNote(d));
						},
						A2(
							$elm$core$List$filter,
							function (d) {
								return !$author$project$Export$isSelected(d);
							},
							discussions))),
				$author$project$Export$atLeastOneDiscussionWasChosen(discussions));
		case 3:
			var projectTitle = _export.a;
			var notes = _export.b;
			return A2($author$project$Export$ConfigureContentView, projectTitle, notes);
		default:
			return $author$project$Export$PromptAnotherExportView;
	}
};
var $author$project$Main$tabView = function (content) {
	var _v0 = content.l;
	switch (_v0.$) {
		case 0:
			var edit = _v0.a;
			var _v1 = A2($author$project$Edit$view, content.Y, edit);
			switch (_v1.$) {
				case 0:
					var filter = _v1.a;
					var discussionFilter = $elm$core$String$isEmpty(filter) ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(filter);
					var data = function () {
						var toDiscussionRecord = function (q) {
							return {
								ax: $author$project$Note$getContent(q),
								eW: q
							};
						};
						return A2(
							$elm$core$List$map,
							toDiscussionRecord,
							A2($author$project$Slipbox$getNotes, discussionFilter, content.Y));
					}();
					return $author$project$Main$column(
						_List_fromArray(
							[
								$author$project$Main$headingCenter('Select Note'),
								A2(
								$mdgriffith$elm_ui$Element$column,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$width(
										A2($mdgriffith$elm_ui$Element$maximum, 600, $mdgriffith$elm_ui$Element$fill)),
										$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
										A2($mdgriffith$elm_ui$Element$spacingXY, 10, 10),
										$mdgriffith$elm_ui$Element$padding(5),
										$mdgriffith$elm_ui$Element$Border$width(2),
										$mdgriffith$elm_ui$Element$Border$rounded(6),
										$mdgriffith$elm_ui$Element$centerX
									]),
								_List_fromArray(
									[
										A3($author$project$Main$multiline, $author$project$Main$EditModeUpdateInput, filter, 'Filter Note'),
										A2(
										$mdgriffith$elm_ui$Element$row,
										_List_fromArray(
											[
												$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
											]),
										_List_fromArray(
											[
												A2(
												$mdgriffith$elm_ui$Element$el,
												_List_fromArray(
													[
														$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
														$mdgriffith$elm_ui$Element$Font$bold,
														$mdgriffith$elm_ui$Element$Border$widthEach(
														{aM: 2, aT: 0, aZ: 0, a_: 0})
													]),
												$mdgriffith$elm_ui$Element$text('Note'))
											])),
										A2(
										$mdgriffith$elm_ui$Element$el,
										_List_fromArray(
											[
												$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
											]),
										A2(
											$mdgriffith$elm_ui$Element$table,
											_List_fromArray(
												[
													$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
													$mdgriffith$elm_ui$Element$padding(8),
													A2($mdgriffith$elm_ui$Element$spacingXY, 8, 8),
													$mdgriffith$elm_ui$Element$centerX,
													$mdgriffith$elm_ui$Element$height(
													A2($mdgriffith$elm_ui$Element$maximum, 300, $mdgriffith$elm_ui$Element$fill)),
													$mdgriffith$elm_ui$Element$scrollbarY
												]),
											{
												b2: _List_fromArray(
													[
														{
														bD: $mdgriffith$elm_ui$Element$none,
														bq: function (row) {
															return A2(
																$author$project$Main$listButton,
																$elm$core$Maybe$Just(
																	$author$project$Main$EditModeSelectNote(row.eW)),
																A2(
																	$mdgriffith$elm_ui$Element$paragraph,
																	_List_Nil,
																	_List_fromArray(
																		[
																			$mdgriffith$elm_ui$Element$text(row.ax)
																		])));
														},
														aL: $mdgriffith$elm_ui$Element$fillPortion(4)
													}
													]),
												b7: data
											}))
									]))
							]));
				case 1:
					var note = _v1.a;
					var maybeSource = _v1.b;
					var directlyLinkedDiscussions = _v1.c;
					var connectedNotes = _v1.d;
					var toLinkedNoteButton = function (_v6) {
						var n = _v6.a;
						var l = _v6.b;
						return A3(
							$author$project$Main$listButtonWithBreakLink,
							$elm$core$Maybe$Just(
								A2($author$project$Main$EditModeConfirmBreakLink, note, l)),
							$elm$core$Maybe$Just(
								$author$project$Main$EditModeSelectNote(n)),
							$author$project$Main$textWrap(
								$author$project$Note$getContent(n)));
					};
					var toDiscussionButton = function (_v5) {
						var n = _v5.a;
						var l = _v5.b;
						return A3(
							$author$project$Main$listButtonWithBreakLink,
							$elm$core$Maybe$Just(
								A2($author$project$Main$EditModeConfirmBreakLink, note, l)),
							$elm$core$Maybe$Just(
								$author$project$Main$EditModeSelectNote(n)),
							$author$project$Main$textWrap(
								$author$project$Note$getContent(n)));
					};
					var textLambda = F2(
						function (title, text) {
							return A2(
								$mdgriffith$elm_ui$Element$column,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$padding(8),
										$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
										$mdgriffith$elm_ui$Element$Border$width(1),
										A2($mdgriffith$elm_ui$Element$spacingXY, 8, 8)
									]),
								_List_fromArray(
									[
										$author$project$Main$heading(title),
										$author$project$Main$textWrap(text)
									]));
						});
					var source = function () {
						if (!maybeSource.$) {
							var s = maybeSource.a;
							return A2(
								textLambda,
								'Source',
								$author$project$Source$getTitle(s));
						} else {
							return A2(
								$mdgriffith$elm_ui$Element$el,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$padding(8),
										$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
										$mdgriffith$elm_ui$Element$Border$width(1),
										A2($mdgriffith$elm_ui$Element$spacingXY, 8, 8)
									]),
								$author$project$Main$heading('No Source'));
						}
					}();
					var linkedNotes = function () {
						if (!connectedNotes.$) {
							var tuples = connectedNotes.a;
							return A2(
								$mdgriffith$elm_ui$Element$column,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
										$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill)
									]),
								_List_fromArray(
									[
										A2(
										$mdgriffith$elm_ui$Element$el,
										_List_fromArray(
											[
												$mdgriffith$elm_ui$Element$padding(8)
											]),
										$author$project$Main$heading('Linked Notes')),
										A2(
										$mdgriffith$elm_ui$Element$column,
										_List_fromArray(
											[
												$mdgriffith$elm_ui$Element$scrollbarY,
												$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
												$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill)
											]),
										A2($elm$core$List$map, toLinkedNoteButton, tuples))
									]));
						} else {
							return A2(
								$mdgriffith$elm_ui$Element$el,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
										$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
										$mdgriffith$elm_ui$Element$padding(8)
									]),
								$author$project$Main$heading('No Linked Notes'));
						}
					}();
					var discussionHeader = A2(
						$mdgriffith$elm_ui$Element$el,
						_List_fromArray(
							[
								$mdgriffith$elm_ui$Element$padding(8)
							]),
						$author$project$Main$heading('Directly Linked Discussions'));
					var discussions = function () {
						if (!directlyLinkedDiscussions.$) {
							var linkedDiscussions = directlyLinkedDiscussions.a;
							return A2(
								$mdgriffith$elm_ui$Element$column,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
										$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
										$mdgriffith$elm_ui$Element$scrollbarY
									]),
								A2(
									$elm$core$List$cons,
									discussionHeader,
									A2($elm$core$List$map, toDiscussionButton, linkedDiscussions)));
						} else {
							return $mdgriffith$elm_ui$Element$none;
						}
					}();
					return A2(
						$mdgriffith$elm_ui$Element$row,
						_List_fromArray(
							[
								$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
								$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
								A2($mdgriffith$elm_ui$Element$spacingXY, 8, 8)
							]),
						_List_fromArray(
							[
								A2(
								$mdgriffith$elm_ui$Element$column,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
										$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill)
									]),
								_List_fromArray(
									[
										A2(
										$mdgriffith$elm_ui$Element$el,
										_List_fromArray(
											[
												$mdgriffith$elm_ui$Element$padding(8)
											]),
										$author$project$Main$heading('Note')),
										A2(
										textLambda,
										'Content',
										$author$project$Note$getContent(note)),
										source,
										discussions,
										A2(
										$author$project$Main$button,
										$elm$core$Maybe$Just($author$project$Main$EditModeSelectNoteScreen),
										$mdgriffith$elm_ui$Element$text('Select Note Screen'))
									])),
								linkedNotes
							]));
				case 2:
					var note = _v1.a;
					var connectedNotes = _v1.b;
					var toLinkedNoteButton = function (_v8) {
						var n = _v8.a;
						var l = _v8.b;
						return A3(
							$author$project$Main$listButtonWithBreakLink,
							$elm$core$Maybe$Just(
								A2($author$project$Main$EditModeConfirmBreakLink, note, l)),
							$elm$core$Maybe$Just(
								$author$project$Main$EditModeSelectNote(n)),
							$author$project$Main$textWrap(
								$author$project$Note$getContent(n)));
					};
					var textLambda = F2(
						function (title, text) {
							return A2(
								$mdgriffith$elm_ui$Element$column,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$padding(8),
										$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
										$mdgriffith$elm_ui$Element$Border$width(1),
										A2($mdgriffith$elm_ui$Element$spacingXY, 8, 8)
									]),
								_List_fromArray(
									[
										$author$project$Main$heading(title),
										$author$project$Main$textWrap(text)
									]));
						});
					var linkedNotes = function () {
						if (!connectedNotes.$) {
							var tuples = connectedNotes.a;
							return A2(
								$mdgriffith$elm_ui$Element$column,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
										$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill)
									]),
								_List_fromArray(
									[
										A2(
										$mdgriffith$elm_ui$Element$el,
										_List_fromArray(
											[
												$mdgriffith$elm_ui$Element$padding(8)
											]),
										$author$project$Main$heading('Linked Notes')),
										A2(
										$mdgriffith$elm_ui$Element$column,
										_List_fromArray(
											[
												$mdgriffith$elm_ui$Element$scrollbarY,
												$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
												$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill)
											]),
										A2($elm$core$List$map, toLinkedNoteButton, tuples))
									]));
						} else {
							return A2(
								$mdgriffith$elm_ui$Element$el,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
										$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
										$mdgriffith$elm_ui$Element$padding(8)
									]),
								$author$project$Main$heading('No Linked Notes'));
						}
					}();
					return A2(
						$mdgriffith$elm_ui$Element$row,
						_List_fromArray(
							[
								$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
								$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
								A2($mdgriffith$elm_ui$Element$spacingXY, 8, 8)
							]),
						_List_fromArray(
							[
								A2(
								$mdgriffith$elm_ui$Element$column,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
										$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill)
									]),
								_List_fromArray(
									[
										A2(
										$mdgriffith$elm_ui$Element$el,
										_List_fromArray(
											[
												$mdgriffith$elm_ui$Element$padding(8)
											]),
										$author$project$Main$heading('Discussion')),
										A2(
										textLambda,
										'Content',
										$author$project$Note$getContent(note)),
										A2(
										$author$project$Main$button,
										$elm$core$Maybe$Just($author$project$Main$EditModeSelectNoteScreen),
										$mdgriffith$elm_ui$Element$text('Select Note Screen'))
									])),
								linkedNotes
							]));
				case 3:
					var linkToBreak = _v1.a;
					var graph = _v1.b;
					var selectedNote = _v1.c;
					var hoverNote = _v1.d;
					return A2(
						$mdgriffith$elm_ui$Element$row,
						_List_fromArray(
							[
								$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
								$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill)
							]),
						_List_fromArray(
							[
								A2(
								$mdgriffith$elm_ui$Element$column,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$width($author$project$Main$smallerElement),
										$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill)
									]),
								_List_fromArray(
									[
										A2(
										$mdgriffith$elm_ui$Element$textColumn,
										_List_fromArray(
											[
												$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
												$mdgriffith$elm_ui$Element$Border$width(1),
												$mdgriffith$elm_ui$Element$padding(8),
												A2($mdgriffith$elm_ui$Element$spacingXY, 10, 10)
											]),
										_List_fromArray(
											[
												$author$project$Main$heading('Selected Note'),
												A2(
												$mdgriffith$elm_ui$Element$paragraph,
												_List_Nil,
												_List_fromArray(
													[
														$mdgriffith$elm_ui$Element$text(
														$author$project$Note$getContent(selectedNote))
													]))
											])),
										A2(
										$mdgriffith$elm_ui$Element$column,
										_List_fromArray(
											[
												$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
												$mdgriffith$elm_ui$Element$Border$width(1),
												$mdgriffith$elm_ui$Element$padding(8),
												A2($mdgriffith$elm_ui$Element$spacingXY, 10, 10)
											]),
										_List_fromArray(
											[
												$author$project$Main$heading('Confirm Break Link'),
												A2(
												$mdgriffith$elm_ui$Element$row,
												_List_fromArray(
													[
														A2($mdgriffith$elm_ui$Element$spacingXY, 10, 10)
													]),
												_List_fromArray(
													[
														A2(
														$author$project$Main$button,
														$elm$core$Maybe$Just($author$project$Main$EditModeConfirm),
														$mdgriffith$elm_ui$Element$text('Confirm')),
														A2(
														$author$project$Main$button,
														$elm$core$Maybe$Just($author$project$Main$EditModeCancel),
														$mdgriffith$elm_ui$Element$text('Cancel'))
													]))
											]))
									])),
								A4(
								$author$project$Main$svgGraph,
								graph,
								$author$project$Main$ConfirmBreakLink(linkToBreak),
								selectedNote,
								hoverNote)
							]));
				case 4:
					return $mdgriffith$elm_ui$Element$text('todo');
				default:
					return $mdgriffith$elm_ui$Element$text('todo');
			}
		case 1:
			var create = _v0.a;
			var _v9 = $author$project$Create$view(create);
			switch (_v9.$) {
				case 0:
					var coachingOpen = _v9.a;
					var canContinue = _v9.b;
					var noteInput = _v9.c;
					var continueNode = canContinue ? A2(
						$author$project$Main$button,
						$elm$core$Maybe$Just($author$project$Main$CreateTabNextStep),
						$mdgriffith$elm_ui$Element$text('Next')) : $mdgriffith$elm_ui$Element$none;
					var coachingText = A2(
						$mdgriffith$elm_ui$Element$paragraph,
						_List_fromArray(
							[
								$mdgriffith$elm_ui$Element$Font$center,
								$mdgriffith$elm_ui$Element$width(
								A2($mdgriffith$elm_ui$Element$maximum, 800, $mdgriffith$elm_ui$Element$fill)),
								$mdgriffith$elm_ui$Element$centerX
							]),
						_List_fromArray(
							[
								$mdgriffith$elm_ui$Element$text('\r\n                  Transform your learning into clear, concise notes with one idea. Write as if you\'ll forget all about this note.\r\n                  When you come across it again, you should be able to read and understand. Take your time, this isn\'t always an easy endeavor.\r\n                  ')
							]));
					return $author$project$Main$column(
						_List_fromArray(
							[
								$author$project$Main$headingCenter('Write a Permanent Note'),
								A2($author$project$Main$coaching, coachingOpen, coachingText),
								A3(
								$author$project$Main$multiline,
								function (n) {
									return $author$project$Main$CreateTabUpdateInput(
										$author$project$Create$Note(n));
								},
								noteInput,
								'Note Content (required)'),
								continueNode
							]));
				case 1:
					var coachingOpen = _v9.a;
					var canContinue = _v9.b;
					var note = _v9.c;
					var discussionsRead = _v9.d;
					var discussions = A2($author$project$Slipbox$getDiscussions, $elm$core$Maybe$Nothing, content.Y);
					var discussionTabularData = function () {
						var toDiscussionRecord = function (q) {
							return {
								ax: $author$project$Note$getContent(q),
								eW: q,
								fb: A2(
									$elm$core$List$any,
									$author$project$Note$is(q),
									discussionsRead)
							};
						};
						return A2($elm$core$List$map, toDiscussionRecord, discussions);
					}();
					var tableNode = function () {
						if ($elm$core$List$isEmpty(discussions)) {
							return A2(
								$mdgriffith$elm_ui$Element$paragraph,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$Font$center,
										$mdgriffith$elm_ui$Element$width(
										A2($mdgriffith$elm_ui$Element$maximum, 800, $mdgriffith$elm_ui$Element$fill)),
										$mdgriffith$elm_ui$Element$centerX
									]),
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$text('There are no discussions in your slipbox! '),
										$mdgriffith$elm_ui$Element$text('We smartly add to our external mind by framing our minds to the perspective of continuing conversation on discussions that interest us. '),
										$mdgriffith$elm_ui$Element$text('Add a discussion in the next step to start linking notes together! ')
									]));
						} else {
							var headerAttrs = _List_fromArray(
								[
									$mdgriffith$elm_ui$Element$Font$bold,
									$mdgriffith$elm_ui$Element$Border$widthEach(
									{aM: 2, aT: 0, aZ: 0, a_: 0})
								]);
							return A2(
								$mdgriffith$elm_ui$Element$column,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$width(
										A2($mdgriffith$elm_ui$Element$maximum, 600, $mdgriffith$elm_ui$Element$fill)),
										$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
										A2($mdgriffith$elm_ui$Element$spacingXY, 10, 10),
										$mdgriffith$elm_ui$Element$padding(5),
										$mdgriffith$elm_ui$Element$Border$width(2),
										$mdgriffith$elm_ui$Element$Border$rounded(6),
										$mdgriffith$elm_ui$Element$centerX
									]),
								_List_fromArray(
									[
										A2(
										$mdgriffith$elm_ui$Element$row,
										_List_fromArray(
											[
												$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
											]),
										_List_fromArray(
											[
												A2(
												$mdgriffith$elm_ui$Element$el,
												A2(
													$elm$core$List$cons,
													$mdgriffith$elm_ui$Element$width(
														$mdgriffith$elm_ui$Element$fillPortion(1)),
													headerAttrs),
												$mdgriffith$elm_ui$Element$text('Read')),
												A2(
												$mdgriffith$elm_ui$Element$el,
												A2(
													$elm$core$List$cons,
													$mdgriffith$elm_ui$Element$width(
														$mdgriffith$elm_ui$Element$fillPortion(4)),
													headerAttrs),
												$mdgriffith$elm_ui$Element$text('Discussion'))
											])),
										A2(
										$mdgriffith$elm_ui$Element$el,
										_List_fromArray(
											[
												$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
											]),
										A2(
											$mdgriffith$elm_ui$Element$table,
											_List_fromArray(
												[
													$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
													A2($mdgriffith$elm_ui$Element$spacingXY, 8, 8),
													$mdgriffith$elm_ui$Element$centerX,
													$mdgriffith$elm_ui$Element$height(
													A2($mdgriffith$elm_ui$Element$maximum, 600, $mdgriffith$elm_ui$Element$fill)),
													$mdgriffith$elm_ui$Element$scrollbarY
												]),
											{
												b2: _List_fromArray(
													[
														{
														bD: $mdgriffith$elm_ui$Element$none,
														bq: function (row) {
															var _v10 = row.fb;
															if (_v10) {
																return $mdgriffith$elm_ui$Element$text('read');
															} else {
																return $mdgriffith$elm_ui$Element$text('unread');
															}
														},
														aL: $mdgriffith$elm_ui$Element$fillPortion(1)
													},
														{
														bD: $mdgriffith$elm_ui$Element$none,
														bq: function (row) {
															return A2(
																$mdgriffith$elm_ui$Element$Input$button,
																_List_Nil,
																{
																	q: A2(
																		$mdgriffith$elm_ui$Element$paragraph,
																		_List_Nil,
																		_List_fromArray(
																			[
																				$mdgriffith$elm_ui$Element$text(row.ax)
																			])),
																	v: $elm$core$Maybe$Just(
																		$author$project$Main$CreateTabToFindLinksForDiscussion(row.eW))
																});
														},
														aL: $mdgriffith$elm_ui$Element$fillPortion(4)
													}
													]),
												b7: discussionTabularData
											}))
									]));
						}
					}();
					var continueLabel = canContinue ? $mdgriffith$elm_ui$Element$text('Continue without linking') : $mdgriffith$elm_ui$Element$text('Next');
					var coachingText = A2(
						$mdgriffith$elm_ui$Element$paragraph,
						_List_fromArray(
							[
								$mdgriffith$elm_ui$Element$Font$center,
								$mdgriffith$elm_ui$Element$width(
								A2($mdgriffith$elm_ui$Element$maximum, 800, $mdgriffith$elm_ui$Element$fill)),
								$mdgriffith$elm_ui$Element$centerX
							]),
						_List_fromArray(
							[
								$mdgriffith$elm_ui$Element$text('\r\n                  Add to existing discussions by linking relevant notes/ideas to that discussion. Click a discussion to get started!\r\n                  Linking knowledge can anything from finding supporting arguments, expanding on a thought, and especially finding counter arguments.\r\n                  Because of confirmation bias, it is hard for us to gather information that opposes what we already know.\r\n                  ')
							]));
					return $author$project$Main$column(
						_List_fromArray(
							[
								$author$project$Main$headingCenter('Further Existing Arguments'),
								A2($author$project$Main$coaching, coachingOpen, coachingText),
								A2(
								$mdgriffith$elm_ui$Element$paragraph,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$Font$center,
										$mdgriffith$elm_ui$Element$width(
										A2($mdgriffith$elm_ui$Element$maximum, 800, $mdgriffith$elm_ui$Element$fill)),
										$mdgriffith$elm_ui$Element$centerX
									]),
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$text(note)
									])),
								A2(
								$author$project$Main$button,
								$elm$core$Maybe$Just($author$project$Main$CreateTabNextStep),
								continueLabel),
								tableNode
							]));
				case 2:
					var createTabGraph = _v9.a;
					var note = _v9.b;
					var discussion = _v9.c;
					var selectedNote = _v9.d;
					var selectedNoteIsLinked = _v9.e;
					var notesAssociatedToCreatedLinks = _v9.f;
					var hoverNote = _v9.g;
					var linkNode = selectedNoteIsLinked ? A2(
						$mdgriffith$elm_ui$Element$column,
						_List_fromArray(
							[
								$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
							]),
						_List_fromArray(
							[
								$mdgriffith$elm_ui$Element$text('Linked'),
								A2(
								$mdgriffith$elm_ui$Element$Input$button,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$padding(8),
										$mdgriffith$elm_ui$Element$Border$width(1)
									]),
								{
									q: $mdgriffith$elm_ui$Element$text('Remove'),
									v: $elm$core$Maybe$Just($author$project$Main$CreateTabRemoveLink)
								})
							])) : A2(
						$mdgriffith$elm_ui$Element$Input$button,
						_List_fromArray(
							[
								$mdgriffith$elm_ui$Element$padding(8),
								$mdgriffith$elm_ui$Element$Border$width(1)
							]),
						{
							q: $mdgriffith$elm_ui$Element$text('Create Link'),
							v: $elm$core$Maybe$Just($author$project$Main$CreateTabCreateLinkForSelectedNote)
						});
					return A2(
						$mdgriffith$elm_ui$Element$row,
						_List_fromArray(
							[
								$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
								$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill)
							]),
						_List_fromArray(
							[
								A2(
								$mdgriffith$elm_ui$Element$column,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$width($author$project$Main$smallerElement),
										$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill)
									]),
								_List_fromArray(
									[
										A2(
										$mdgriffith$elm_ui$Element$textColumn,
										_List_fromArray(
											[
												$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
												$mdgriffith$elm_ui$Element$padding(8),
												$mdgriffith$elm_ui$Element$Border$width(1),
												A2($mdgriffith$elm_ui$Element$spacingXY, 10, 10)
											]),
										_List_fromArray(
											[
												$author$project$Main$heading('Discussion'),
												A2(
												$mdgriffith$elm_ui$Element$paragraph,
												_List_Nil,
												_List_fromArray(
													[
														$mdgriffith$elm_ui$Element$text(
														$author$project$Note$getContent(discussion))
													]))
											])),
										A2(
										$mdgriffith$elm_ui$Element$textColumn,
										_List_fromArray(
											[
												$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
												$mdgriffith$elm_ui$Element$Border$width(1),
												$mdgriffith$elm_ui$Element$padding(8),
												A2($mdgriffith$elm_ui$Element$spacingXY, 10, 10)
											]),
										_List_fromArray(
											[
												$author$project$Main$heading('Created Note'),
												A2(
												$mdgriffith$elm_ui$Element$paragraph,
												_List_Nil,
												_List_fromArray(
													[
														$mdgriffith$elm_ui$Element$text(note)
													]))
											])),
										A2(
										$mdgriffith$elm_ui$Element$column,
										_List_fromArray(
											[
												$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
												$mdgriffith$elm_ui$Element$Border$width(1),
												$mdgriffith$elm_ui$Element$padding(8),
												A2($mdgriffith$elm_ui$Element$spacingXY, 10, 10)
											]),
										_List_fromArray(
											[
												A2(
												$mdgriffith$elm_ui$Element$textColumn,
												_List_fromArray(
													[
														A2($mdgriffith$elm_ui$Element$spacingXY, 10, 10)
													]),
												_List_fromArray(
													[
														$author$project$Main$heading('Selected Note'),
														A2(
														$mdgriffith$elm_ui$Element$paragraph,
														_List_Nil,
														_List_fromArray(
															[
																$mdgriffith$elm_ui$Element$text(
																$author$project$Note$getContent(selectedNote))
															]))
													])),
												linkNode
											])),
										A2(
										$author$project$Main$button,
										$elm$core$Maybe$Just($author$project$Main$CreateTabToChooseDiscussion),
										$mdgriffith$elm_ui$Element$text('Done Linking'))
									])),
								A4(
								$author$project$Main$svgGraph,
								createTabGraph,
								$author$project$Main$DiscussionChosenView(notesAssociatedToCreatedLinks),
								selectedNote,
								hoverNote)
							]));
				case 3:
					var note = _v9.a;
					var input = _v9.b;
					var continueNode = $elm$core$String$isEmpty(input) ? A2(
						$mdgriffith$elm_ui$Element$el,
						_List_fromArray(
							[
								$mdgriffith$elm_ui$Element$height(
								$mdgriffith$elm_ui$Element$px(38))
							]),
						$mdgriffith$elm_ui$Element$none) : A2(
						$mdgriffith$elm_ui$Element$el,
						_List_fromArray(
							[
								$mdgriffith$elm_ui$Element$moveRight(16)
							]),
						A2(
							$author$project$Main$button,
							$elm$core$Maybe$Just($author$project$Main$CreateTabSubmitNewDiscussion),
							$mdgriffith$elm_ui$Element$text('Create and Link Discussion')));
					return $author$project$Main$column(
						_List_fromArray(
							[
								$author$project$Main$headingCenter('Is this note the start of its own discussion/a new discussion?'),
								A2(
								$mdgriffith$elm_ui$Element$paragraph,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$Font$center,
										$mdgriffith$elm_ui$Element$width(
										A2($mdgriffith$elm_ui$Element$maximum, 800, $mdgriffith$elm_ui$Element$fill)),
										$mdgriffith$elm_ui$Element$centerX
									]),
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$text(note)
									])),
								A3(
								$author$project$Main$multiline,
								function (n) {
									return $author$project$Main$CreateTabUpdateInput(
										$author$project$Create$Note(n));
								},
								input,
								'Discussion'),
								continueNode,
								A2(
								$author$project$Main$button,
								$elm$core$Maybe$Just($author$project$Main$CreateTabNextStep),
								$mdgriffith$elm_ui$Element$text('This isn\'t the start of a new discussion'))
							]));
				case 4:
					var note = _v9.a;
					var input = _v9.b;
					var existingSources = A2($author$project$Slipbox$getSources, $elm$core$Maybe$Nothing, content.Y);
					var maybeSourceSelected = $elm$core$List$head(
						A2(
							$elm$core$List$filter,
							function (source) {
								return _Utils_eq(
									$author$project$Source$getTitle(source),
									input);
							},
							existingSources));
					var useExistingSourceNode = function () {
						if (!maybeSourceSelected.$) {
							var source = maybeSourceSelected.a;
							return A2(
								$mdgriffith$elm_ui$Element$el,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$moveRight(16)
									]),
								A2(
									$author$project$Main$button,
									$elm$core$Maybe$Just(
										$author$project$Main$CreateTabContinueWithSelectedSource(source)),
									$mdgriffith$elm_ui$Element$text('Use Selected Source')));
						} else {
							return $mdgriffith$elm_ui$Element$none;
						}
					}();
					return $author$project$Main$column(
						_List_fromArray(
							[
								$author$project$Main$headingCenter('Attribute a Source'),
								A2(
								$mdgriffith$elm_ui$Element$paragraph,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$Font$center,
										$mdgriffith$elm_ui$Element$width(
										A2($mdgriffith$elm_ui$Element$maximum, 800, $mdgriffith$elm_ui$Element$fill)),
										$mdgriffith$elm_ui$Element$centerX
									]),
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$text(note)
									])),
								A2(
								$mdgriffith$elm_ui$Element$el,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$centerX,
										$mdgriffith$elm_ui$Element$onRight(useExistingSourceNode)
									]),
								A2(
									$author$project$Main$createTabSourceInput,
									input,
									A2($elm$core$List$map, $author$project$Source$getTitle, existingSources))),
								A2(
								$author$project$Main$button,
								$elm$core$Maybe$Just($author$project$Main$CreateTabNoSource),
								$mdgriffith$elm_ui$Element$text('No Source')),
								A2(
								$author$project$Main$button,
								$elm$core$Maybe$Just($author$project$Main$CreateTabNewSource),
								$mdgriffith$elm_ui$Element$text('New Source'))
							]));
				case 5:
					var note = _v9.a;
					var title = _v9.b;
					var author = _v9.c;
					var sourceContent = _v9.d;
					var msgLambda = function (updateMethod) {
						return function (s) {
							return $author$project$Main$CreateTabUpdateInput(
								updateMethod(s));
						};
					};
					var existingTitles = A2(
						$elm$core$List$map,
						$author$project$Source$getTitle,
						A2($author$project$Slipbox$getSources, $elm$core$Maybe$Nothing, content.Y));
					var _v12 = A2($author$project$SourceTitle$validateNewSourceTitle, existingTitles, title) ? _Utils_Tuple2(
						'Title (required)',
						A2(
							$author$project$Main$button,
							$elm$core$Maybe$Just($author$project$Main$CreateTabSubmitNewSource),
							$mdgriffith$elm_ui$Element$text('Submit New Source'))) : ($elm$core$String$isEmpty(title) ? _Utils_Tuple2('Title (required)', $mdgriffith$elm_ui$Element$none) : _Utils_Tuple2('Title is not valid. Titles must be unique and may not be \'n/a\' or empty', $mdgriffith$elm_ui$Element$none));
					var titleLabel = _v12.a;
					var submitNode = _v12.b;
					return $author$project$Main$column(
						_List_fromArray(
							[
								$author$project$Main$headingCenter('Create a Source'),
								A2(
								$mdgriffith$elm_ui$Element$paragraph,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$Font$center,
										$mdgriffith$elm_ui$Element$width(
										A2($mdgriffith$elm_ui$Element$maximum, 800, $mdgriffith$elm_ui$Element$fill)),
										$mdgriffith$elm_ui$Element$centerX
									]),
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$text(note)
									])),
								A3(
								$author$project$Main$multiline,
								msgLambda($author$project$Create$SourceTitle),
								title,
								titleLabel),
								A3(
								$author$project$Main$multiline,
								msgLambda($author$project$Create$SourceAuthor),
								author,
								'Author (not required)'),
								A3(
								$author$project$Main$multiline,
								msgLambda($author$project$Create$SourceContent),
								sourceContent,
								'Content (not required)'),
								submitNode
							]));
				default:
					var note = _v9.a;
					return $author$project$Main$column(
						_List_fromArray(
							[
								$author$project$Main$headingCenter('Success! You\'ve smartly added to your external mind. '),
								A2(
								$mdgriffith$elm_ui$Element$paragraph,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$Font$center,
										$mdgriffith$elm_ui$Element$width(
										A2($mdgriffith$elm_ui$Element$maximum, 800, $mdgriffith$elm_ui$Element$fill)),
										$mdgriffith$elm_ui$Element$centerX
									]),
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$text(note)
									])),
								A2(
								$author$project$Main$button,
								$elm$core$Maybe$Just($author$project$Main$CreateTabCreateAnotherNote),
								$mdgriffith$elm_ui$Element$text('Create Another Note?'))
							]));
			}
		case 2:
			var discovery = _v0.a;
			var _v13 = $author$project$Discovery$view(discovery);
			switch (_v13.$) {
				case 0:
					var discussion = _v13.a;
					var selectedNote = _v13.b;
					var discussionGraph = _v13.c;
					var hoverNote = _v13.d;
					var viewDiscussionNode = (($author$project$Note$getVariant(selectedNote) === 1) && (!A2($author$project$Note$is, discussion, selectedNote))) ? A2(
						$author$project$Main$button,
						$elm$core$Maybe$Just(
							$author$project$Main$DiscoveryModeSelectDiscussion(selectedNote)),
						A2(
							$mdgriffith$elm_ui$Element$el,
							_List_fromArray(
								[$mdgriffith$elm_ui$Element$centerX]),
							$mdgriffith$elm_ui$Element$text('Go to Discussion'))) : ((!$author$project$Note$getVariant(selectedNote)) ? A2(
						$author$project$Main$button,
						$elm$core$Maybe$Just($author$project$Main$DiscoveryModeStartNewDiscussion),
						A2(
							$mdgriffith$elm_ui$Element$el,
							_List_fromArray(
								[$mdgriffith$elm_ui$Element$centerX]),
							$mdgriffith$elm_ui$Element$text('Designate New Discussion Entry Point'))) : $mdgriffith$elm_ui$Element$none);
					return A2(
						$mdgriffith$elm_ui$Element$row,
						_List_fromArray(
							[
								$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
								$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill)
							]),
						_List_fromArray(
							[
								A2(
								$mdgriffith$elm_ui$Element$column,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$width($author$project$Main$smallerElement),
										$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill)
									]),
								_List_fromArray(
									[
										A2(
										$mdgriffith$elm_ui$Element$textColumn,
										_List_fromArray(
											[
												$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
												$mdgriffith$elm_ui$Element$Border$width(1),
												$mdgriffith$elm_ui$Element$padding(8),
												A2($mdgriffith$elm_ui$Element$spacingXY, 10, 10)
											]),
										_List_fromArray(
											[
												$author$project$Main$heading('Selected Discussion'),
												A2(
												$mdgriffith$elm_ui$Element$paragraph,
												_List_Nil,
												_List_fromArray(
													[
														$mdgriffith$elm_ui$Element$text(
														$author$project$Note$getContent(discussion))
													]))
											])),
										A2(
										$mdgriffith$elm_ui$Element$textColumn,
										_List_fromArray(
											[
												$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
												$mdgriffith$elm_ui$Element$Border$width(1),
												$mdgriffith$elm_ui$Element$padding(8),
												A2($mdgriffith$elm_ui$Element$spacingXY, 10, 10)
											]),
										_List_fromArray(
											[
												$author$project$Main$heading('Selected Note'),
												A2(
												$mdgriffith$elm_ui$Element$paragraph,
												_List_Nil,
												_List_fromArray(
													[
														$mdgriffith$elm_ui$Element$text(
														$author$project$Note$getContent(selectedNote))
													])),
												A2(
												$author$project$Main$button,
												$elm$core$Maybe$Just(
													$author$project$Main$EditModeSelectNote(selectedNote)),
												A2(
													$mdgriffith$elm_ui$Element$el,
													_List_fromArray(
														[$mdgriffith$elm_ui$Element$centerX]),
													$mdgriffith$elm_ui$Element$text('Open Note'))),
												viewDiscussionNode
											])),
										A2(
										$author$project$Main$button,
										$elm$core$Maybe$Just($author$project$Main$DiscoveryModeBack),
										$mdgriffith$elm_ui$Element$text('Back'))
									])),
								A4($author$project$Main$svgGraph, discussionGraph, $author$project$Main$ViewDiscussionView, selectedNote, hoverNote)
							]));
				case 1:
					var filterInput = _v13.a;
					var discussionFilter = $elm$core$String$isEmpty(filterInput) ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(filterInput);
					var discussionTabularData = function () {
						var toDiscussionRecord = function (q) {
							return {
								ax: $author$project$Note$getContent(q),
								eW: q
							};
						};
						return A2(
							$elm$core$List$map,
							toDiscussionRecord,
							A2($author$project$Slipbox$getDiscussions, discussionFilter, content.Y));
					}();
					return $author$project$Main$column(
						_List_fromArray(
							[
								$author$project$Main$headingCenter('Select Discussion'),
								A2(
								$mdgriffith$elm_ui$Element$column,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$width(
										A2($mdgriffith$elm_ui$Element$maximum, 600, $mdgriffith$elm_ui$Element$fill)),
										$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
										A2($mdgriffith$elm_ui$Element$spacingXY, 10, 10),
										$mdgriffith$elm_ui$Element$padding(5),
										$mdgriffith$elm_ui$Element$Border$width(2),
										$mdgriffith$elm_ui$Element$Border$rounded(6),
										$mdgriffith$elm_ui$Element$centerX
									]),
								_List_fromArray(
									[
										A3($author$project$Main$multiline, $author$project$Main$DiscoveryModeUpdateInput, filterInput, 'Filter Discussion'),
										A2(
										$mdgriffith$elm_ui$Element$row,
										_List_fromArray(
											[
												$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
											]),
										_List_fromArray(
											[
												A2(
												$mdgriffith$elm_ui$Element$el,
												_List_fromArray(
													[
														$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
														$mdgriffith$elm_ui$Element$Font$bold,
														$mdgriffith$elm_ui$Element$Border$widthEach(
														{aM: 2, aT: 0, aZ: 0, a_: 0})
													]),
												$mdgriffith$elm_ui$Element$text('Discussion'))
											])),
										A2(
										$mdgriffith$elm_ui$Element$el,
										_List_fromArray(
											[
												$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
											]),
										A2(
											$mdgriffith$elm_ui$Element$table,
											_List_fromArray(
												[
													$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
													A2($mdgriffith$elm_ui$Element$spacingXY, 8, 8),
													$mdgriffith$elm_ui$Element$centerX,
													$mdgriffith$elm_ui$Element$height(
													A2($mdgriffith$elm_ui$Element$maximum, 600, $mdgriffith$elm_ui$Element$fill)),
													$mdgriffith$elm_ui$Element$scrollbarY
												]),
											{
												b2: _List_fromArray(
													[
														{
														bD: $mdgriffith$elm_ui$Element$none,
														bq: function (row) {
															return A2(
																$mdgriffith$elm_ui$Element$Input$button,
																_List_Nil,
																{
																	q: A2(
																		$mdgriffith$elm_ui$Element$paragraph,
																		_List_Nil,
																		_List_fromArray(
																			[
																				$mdgriffith$elm_ui$Element$text(row.ax)
																			])),
																	v: $elm$core$Maybe$Just(
																		$author$project$Main$DiscoveryModeSelectDiscussion(row.eW))
																});
														},
														aL: $mdgriffith$elm_ui$Element$fillPortion(4)
													}
													]),
												b7: discussionTabularData
											}))
									]))
							]));
				default:
					var selectedNote = _v13.a;
					var input = _v13.b;
					var matchingDiscussionExists = A2(
						$elm$core$List$any,
						function (discussion) {
							return _Utils_eq(
								$author$project$Note$getContent(discussion),
								input);
						},
						A2($author$project$Slipbox$getDiscussions, $elm$core$Maybe$Nothing, content.Y));
					var submitNode = matchingDiscussionExists ? A2(
						$mdgriffith$elm_ui$Element$el,
						_List_fromArray(
							[$mdgriffith$elm_ui$Element$centerX]),
						$mdgriffith$elm_ui$Element$text('Discussion already exists!')) : ($elm$core$String$isEmpty(input) ? A2(
						$mdgriffith$elm_ui$Element$el,
						_List_fromArray(
							[
								$mdgriffith$elm_ui$Element$height(
								A2($mdgriffith$elm_ui$Element$minimum, 10, $mdgriffith$elm_ui$Element$fill)),
								$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
							]),
						$mdgriffith$elm_ui$Element$none) : A2(
						$author$project$Main$button,
						$elm$core$Maybe$Just($author$project$Main$DiscoveryModeSubmit),
						$mdgriffith$elm_ui$Element$text('Submit New Discussion')));
					return $author$project$Main$column(
						_List_fromArray(
							[
								$author$project$Main$headingCenter('New Discussion Discovery'),
								A2(
								$mdgriffith$elm_ui$Element$paragraph,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$Font$center,
										$mdgriffith$elm_ui$Element$width(
										A2($mdgriffith$elm_ui$Element$maximum, 800, $mdgriffith$elm_ui$Element$fill)),
										$mdgriffith$elm_ui$Element$centerX
									]),
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$text(selectedNote)
									])),
								A3($author$project$Main$multiline, $author$project$Main$DiscoveryModeUpdateInput, input, 'Discussion'),
								submitNode,
								A2(
								$author$project$Main$button,
								$elm$core$Maybe$Just($author$project$Main$DiscoveryModeBack),
								$mdgriffith$elm_ui$Element$text('Cancel'))
							]));
			}
		default:
			var _export = _v0.a;
			var _v14 = $author$project$Export$view(_export);
			switch (_v14.$) {
				case 0:
					return $author$project$Main$column(
						_List_fromArray(
							[
								$author$project$Main$headingCenter('We cannot start export mode without discussions!'),
								A2(
								$mdgriffith$elm_ui$Element$paragraph,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$width(
										A2($mdgriffith$elm_ui$Element$maximum, 800, $mdgriffith$elm_ui$Element$fill)),
										$mdgriffith$elm_ui$Element$centerX
									]),
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$text('Export Mode is used to bring discussions out of the app and into your hands! '),
										$mdgriffith$elm_ui$Element$text('Start some discussions! Adding relevant facts to discussions is the sustainable way to use this application! '),
										$mdgriffith$elm_ui$Element$text('When you have a discussion you want to do something with, come back here! '),
										$mdgriffith$elm_ui$Element$text('As you build up your knowledge, your discussions will be come richer with knowledge and more useful to you. '),
										$mdgriffith$elm_ui$Element$text('We bet you will much to share soon! ')
									])),
								A2(
								$author$project$Main$button,
								$elm$core$Maybe$Just(
									$author$project$Main$ChangeTab(1)),
								$mdgriffith$elm_ui$Element$text('Create Notes and Discussions'))
							]));
				case 1:
					var title = _v14.a;
					var canContinue = _v14.b;
					var buttonNode = canContinue ? A2(
						$author$project$Main$button,
						$elm$core$Maybe$Just($author$project$Main$ExportModeContinue),
						$mdgriffith$elm_ui$Element$text('Continue')) : $mdgriffith$elm_ui$Element$none;
					return $author$project$Main$column(
						_List_fromArray(
							[
								$author$project$Main$headingCenter('Give a title to the project you\'re exporting!'),
								A3($author$project$Main$multiline, $author$project$Main$ExportModeUpdateInput, title, 'Project Title (required)'),
								buttonNode
							]));
				case 2:
					var title = _v14.a;
					var filter = _v14.b;
					var selectedDiscussions = _v14.c;
					var unselectedFilteredDiscussions = _v14.d;
					var canContinue = _v14.e;
					var continueNodeWithSelectedDiscussions = canContinue ? $author$project$Main$column(
						_List_fromArray(
							[
								$author$project$Main$headingCenter('Selected Discussions'),
								$author$project$Main$column(
								A2(
									$elm$core$List$map,
									function (d) {
										return A2(
											$mdgriffith$elm_ui$Element$row,
											_List_fromArray(
												[
													$mdgriffith$elm_ui$Element$Border$width(1),
													$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
													$mdgriffith$elm_ui$Element$width(
													A2($mdgriffith$elm_ui$Element$maximum, 600, $mdgriffith$elm_ui$Element$fill)),
													$mdgriffith$elm_ui$Element$centerX
												]),
											_List_fromArray(
												[
													A2(
													$mdgriffith$elm_ui$Element$el,
													_List_fromArray(
														[
															$mdgriffith$elm_ui$Element$paddingEach($author$project$Main$leftPad)
														]),
													$mdgriffith$elm_ui$Element$text(
														$author$project$Note$getContent(d))),
													A2(
													$mdgriffith$elm_ui$Element$el,
													_List_fromArray(
														[$mdgriffith$elm_ui$Element$alignRight]),
													A2(
														$author$project$Main$button,
														$elm$core$Maybe$Just(
															$author$project$Main$ExportModeToggleDiscussion(d)),
														$mdgriffith$elm_ui$Element$text('Unselect Discussion')))
												]));
									},
									selectedDiscussions)),
								A2(
								$author$project$Main$button,
								$elm$core$Maybe$Just($author$project$Main$ExportModeContinue),
								$mdgriffith$elm_ui$Element$text('Continue'))
							])) : $mdgriffith$elm_ui$Element$none;
					return $author$project$Main$column(
						_List_fromArray(
							[
								$author$project$Main$headingCenter('Select Relevant Discussions to Project'),
								A2(
								$mdgriffith$elm_ui$Element$el,
								_List_fromArray(
									[$mdgriffith$elm_ui$Element$centerX]),
								$mdgriffith$elm_ui$Element$text(title)),
								continueNodeWithSelectedDiscussions,
								A2(
								$mdgriffith$elm_ui$Element$column,
								_List_fromArray(
									[
										$mdgriffith$elm_ui$Element$width(
										A2($mdgriffith$elm_ui$Element$maximum, 600, $mdgriffith$elm_ui$Element$fill)),
										$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
										A2($mdgriffith$elm_ui$Element$spacingXY, 10, 10),
										$mdgriffith$elm_ui$Element$padding(5),
										$mdgriffith$elm_ui$Element$Border$width(2),
										$mdgriffith$elm_ui$Element$Border$rounded(6),
										$mdgriffith$elm_ui$Element$centerX
									]),
								_List_fromArray(
									[
										A3($author$project$Main$multiline, $author$project$Main$ExportModeUpdateInput, filter, 'Filter Note'),
										A2(
										$mdgriffith$elm_ui$Element$row,
										_List_fromArray(
											[
												$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
											]),
										_List_fromArray(
											[
												A2(
												$mdgriffith$elm_ui$Element$el,
												_List_fromArray(
													[
														$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
														$mdgriffith$elm_ui$Element$Font$bold,
														$mdgriffith$elm_ui$Element$Border$widthEach(
														{aM: 2, aT: 0, aZ: 0, a_: 0})
													]),
												$mdgriffith$elm_ui$Element$text('Select Discussions'))
											])),
										A2(
										$mdgriffith$elm_ui$Element$el,
										_List_fromArray(
											[
												$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
											]),
										A2(
											$mdgriffith$elm_ui$Element$table,
											_List_fromArray(
												[
													$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
													$mdgriffith$elm_ui$Element$padding(8),
													A2($mdgriffith$elm_ui$Element$spacingXY, 8, 8),
													$mdgriffith$elm_ui$Element$centerX,
													$mdgriffith$elm_ui$Element$height(
													A2($mdgriffith$elm_ui$Element$maximum, 300, $mdgriffith$elm_ui$Element$fill)),
													$mdgriffith$elm_ui$Element$scrollbarY
												]),
											{
												b2: _List_fromArray(
													[
														{
														bD: $mdgriffith$elm_ui$Element$none,
														bq: function (row) {
															return A2(
																$author$project$Main$listButton,
																$elm$core$Maybe$Just(
																	$author$project$Main$ExportModeToggleDiscussion(row.eW)),
																A2(
																	$mdgriffith$elm_ui$Element$paragraph,
																	_List_Nil,
																	_List_fromArray(
																		[
																			$mdgriffith$elm_ui$Element$text(row.ax)
																		])));
														},
														aL: $mdgriffith$elm_ui$Element$fillPortion(4)
													}
													]),
												b7: A2(
													$elm$core$List$map,
													function (q) {
														return {
															ax: $author$project$Note$getContent(q),
															eW: q
														};
													},
													unselectedFilteredDiscussions)
											}))
									]))
							]));
				case 3:
					var title = _v14.a;
					var notes = _v14.b;
					return $author$project$Main$column(
						_List_fromArray(
							[
								$author$project$Main$headingCenter('Configure Notes'),
								A2(
								$mdgriffith$elm_ui$Element$el,
								_List_fromArray(
									[$mdgriffith$elm_ui$Element$centerX]),
								$mdgriffith$elm_ui$Element$text(title)),
								A2(
								$author$project$Main$button,
								$elm$core$Maybe$Just($author$project$Main$ExportModeFinish),
								$mdgriffith$elm_ui$Element$text('Continue')),
								$author$project$Main$column(
								A2(
									$elm$core$List$map,
									function (d) {
										return A2(
											$mdgriffith$elm_ui$Element$row,
											_List_fromArray(
												[
													$mdgriffith$elm_ui$Element$Border$width(1),
													$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
													$mdgriffith$elm_ui$Element$width(
													A2($mdgriffith$elm_ui$Element$maximum, 600, $mdgriffith$elm_ui$Element$fill)),
													$mdgriffith$elm_ui$Element$centerX
												]),
											_List_fromArray(
												[
													A2(
													$mdgriffith$elm_ui$Element$paragraph,
													_List_fromArray(
														[
															$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
															$mdgriffith$elm_ui$Element$padding(8)
														]),
													_List_fromArray(
														[
															$mdgriffith$elm_ui$Element$text(
															$author$project$Note$getContent(d))
														])),
													A2(
													$mdgriffith$elm_ui$Element$el,
													_List_fromArray(
														[$mdgriffith$elm_ui$Element$alignRight]),
													A2(
														$author$project$Main$button,
														$elm$core$Maybe$Just(
															$author$project$Main$ExportModeRemove(d)),
														$mdgriffith$elm_ui$Element$text('Remove Note')))
												]));
									},
									notes))
							]));
				default:
					return $author$project$Main$column(
						_List_fromArray(
							[
								$author$project$Main$headingCenter('Success! Your new project has downloaded. '),
								A2(
								$author$project$Main$button,
								$elm$core$Maybe$Just($author$project$Main$ExportModeContinue),
								$mdgriffith$elm_ui$Element$text('Start Another Project'))
							]));
			}
	}
};
var $author$project$Main$sessionNode = function (content) {
	return A2(
		$mdgriffith$elm_ui$Element$row,
		_List_fromArray(
			[
				$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
				$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill)
			]),
		_List_fromArray(
			[
				A3($author$project$Main$leftNav, content.cl, content.l, content.Y),
				A2(
				$mdgriffith$elm_ui$Element$el,
				_List_fromArray(
					[
						$mdgriffith$elm_ui$Element$width($author$project$Main$biggerElement),
						$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill)
					]),
				$author$project$Main$tabView(content))
			]));
};
var $author$project$Main$sessionView = function (content) {
	return $author$project$Main$layoutWithFontAwesomeStyles(
		$author$project$Main$sessionNode(content));
};
var $author$project$Main$FileRequested = {$: 3};
var $author$project$Main$InitializeNewSlipbox = {$: 2};
var $author$project$Main$barHeight = 65;
var $mdgriffith$elm_ui$Element$moveLeft = function (x) {
	return A2(
		$mdgriffith$elm_ui$Internal$Model$TransformComponent,
		$mdgriffith$elm_ui$Internal$Flag$moveX,
		$mdgriffith$elm_ui$Internal$Model$MoveX(-x));
};
var $mdgriffith$elm_ui$Element$rgb255 = F3(
	function (red, green, blue) {
		return A4($mdgriffith$elm_ui$Internal$Model$Rgba, red / 255, green / 255, blue / 255, 1);
	});
var $author$project$Color$white = A3($mdgriffith$elm_ui$Element$rgb255, 255, 255, 255);
var $author$project$Main$setupOverlay = function () {
	var xButton = A2(
		$mdgriffith$elm_ui$Element$el,
		_List_fromArray(
			[
				$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
			]),
		A2(
			$mdgriffith$elm_ui$Element$Input$button,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$alignRight,
					$mdgriffith$elm_ui$Element$moveLeft(2)
				]),
			{
				q: $mdgriffith$elm_ui$Element$text('x'),
				v: $elm$core$Maybe$Just($author$project$Main$InitializeNewSlipbox)
			}));
	var buttonBuilder = function (func) {
		return A2(
			$mdgriffith$elm_ui$Element$Input$button,
			_List_fromArray(
				[$mdgriffith$elm_ui$Element$centerX, $mdgriffith$elm_ui$Element$centerY]),
			func);
	};
	return A2(
		$mdgriffith$elm_ui$Element$el,
		_List_fromArray(
			[
				$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
				$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
				$mdgriffith$elm_ui$Element$padding($author$project$Main$barHeight)
			]),
		A2(
			$mdgriffith$elm_ui$Element$el,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$width(
					$mdgriffith$elm_ui$Element$px(450)),
					$mdgriffith$elm_ui$Element$height(
					$mdgriffith$elm_ui$Element$px(150)),
					$mdgriffith$elm_ui$Element$centerX,
					$mdgriffith$elm_ui$Element$centerY,
					$mdgriffith$elm_ui$Element$Border$width(1),
					$mdgriffith$elm_ui$Element$Background$color($author$project$Color$white),
					$mdgriffith$elm_ui$Element$inFront(xButton),
					A2($mdgriffith$elm_ui$Element$paddingXY, 0, 16)
				]),
			A2(
				$mdgriffith$elm_ui$Element$row,
				_List_fromArray(
					[
						$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
						$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
					]),
				_List_fromArray(
					[
						A2(
						$mdgriffith$elm_ui$Element$el,
						_List_fromArray(
							[
								$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
								$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill),
								$mdgriffith$elm_ui$Element$Border$widthEach(
								{aM: 0, aT: 0, aZ: 1, a_: 0})
							]),
						buttonBuilder(
							{
								q: A2(
									$mdgriffith$elm_ui$Element$el,
									_List_fromArray(
										[$mdgriffith$elm_ui$Element$centerX, $mdgriffith$elm_ui$Element$Font$underline]),
									$mdgriffith$elm_ui$Element$text('Start New')),
								v: $elm$core$Maybe$Just($author$project$Main$InitializeNewSlipbox)
							})),
						A2(
						$mdgriffith$elm_ui$Element$el,
						_List_fromArray(
							[
								$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
								$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
							]),
						buttonBuilder(
							{
								q: A2(
									$mdgriffith$elm_ui$Element$el,
									_List_fromArray(
										[$mdgriffith$elm_ui$Element$centerX, $mdgriffith$elm_ui$Element$Font$underline]),
									$mdgriffith$elm_ui$Element$text('Load Slipbox')),
								v: $elm$core$Maybe$Just($author$project$Main$FileRequested)
							}))
					]))));
}();
var $author$project$Main$setupView = A2(
	$elm$html$Html$div,
	_List_fromArray(
		[
			A2($elm$html$Html$Attributes$style, 'height', '100%'),
			A2($elm$html$Html$Attributes$style, 'width', '100%')
		]),
	_List_fromArray(
		[
			$lattyware$elm_fontawesome$FontAwesome$Styles$css,
			A2(
			$mdgriffith$elm_ui$Element$layout,
			_List_fromArray(
				[
					$mdgriffith$elm_ui$Element$inFront($author$project$Main$setupOverlay)
				]),
			A2(
				$mdgriffith$elm_ui$Element$el,
				_List_fromArray(
					[
						$mdgriffith$elm_ui$Element$alpha(0.3),
						$mdgriffith$elm_ui$Element$height($mdgriffith$elm_ui$Element$fill),
						$mdgriffith$elm_ui$Element$width($mdgriffith$elm_ui$Element$fill)
					]),
				$author$project$Main$sessionNode($author$project$Main$newContent)))
		]));
var $author$project$Main$webpageTitle = 'Slipbox ' + $author$project$Main$versionString;
var $author$project$Main$view = function (model) {
	switch (model.$) {
		case 0:
			return {
				cC: _List_fromArray(
					[$author$project$Main$setupView]),
				dO: $author$project$Main$webpageTitle
			};
		case 1:
			return {
				cC: _List_fromArray(
					[
						A2(
						$mdgriffith$elm_ui$Element$layout,
						_List_Nil,
						$mdgriffith$elm_ui$Element$text('Failure to read file, please reload the page.'))
					]),
				dO: $author$project$Main$webpageTitle
			};
		default:
			var content = model.a;
			return {
				cC: _List_fromArray(
					[
						$author$project$Main$sessionView(content)
					]),
				dO: $author$project$Main$webpageTitle
			};
	}
};
var $author$project$Main$main = $elm$browser$Browser$application(
	{gK: $author$project$Main$init, g5: $author$project$Main$UrlChanged, g6: $author$project$Main$LinkClicked, hK: $author$project$Main$subscriptions, h8: $author$project$Main$update, bq: $author$project$Main$view});
_Platform_export({'Main':{'init':$author$project$Main$main(
	$elm$json$Json$Decode$succeed(0))(0)}});}(this));