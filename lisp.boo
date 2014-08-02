import System

class Nil:
  def ToString():
    return 'nil'

class Num:
  public data as int
  def constructor(n as int):
    data = n
  def ToString():
    return data.ToString()

class Sym:
  public data as string
  def constructor(s as string):
    data = s
  def ToString():
    return data

class Error:
  public data as string
  def constructor(s as string):
    data = s
  def ToString():
    return data

class Cons:
  public car as object
  public cdr as object
  def constructor(a, d):
    car = a
    cdr = d
  def ToString():
    obj as object = self
    ret = ''
    first = true
    while obj.GetType() == Cons:
      if first:
        first = false
      else:
        ret += ' '
      cell = toCons(obj)
      ret += cell.car.ToString()
      obj = cell.cdr
    if obj.GetType() == Nil:
      return '(' + ret + ')'
    else:
      return '(' + ret + ' . ' + obj.ToString() + ')'

class ParseState:
  public elm as object
  public next as string
  def constructor(o, s):
    elm = o
    next = s

callable Printer(obj as object) as string

def toNum(obj):
  ret = obj cast Num
  return ret
def toSym(obj):
  ret = obj cast Sym
  return ret
def toError(obj):
  ret = obj cast Error
  return ret
def toCons(obj):
  ret = obj cast Cons
  return ret

kLPar = char('(')
kRPar = char(')')
kQuote = char('\'')

kNil = Nil()

sym_table = {'nil': kNil}
def makeSym(s as string):
  if not sym_table.Contains(s):
    sym_table[s] = Sym(s)
  return sym_table[s]

sym_t = makeSym('t')
sym_quote = makeSym('quote')

def safeCar(obj as object):
  if obj.GetType() == Cons:
    return toCons(obj).car
  return kNil

def safeCdr(obj as object):
  if obj.GetType() == Cons:
    return toCons(obj).cdr
  return kNil

def nreverse(lst as object):
  ret as object = kNil
  while lst.GetType() == Cons:
    cell = toCons(lst)
    tmp = cell.cdr
    cell.cdr = ret
    ret = lst
    lst = tmp
  return ret

def isSpace(c as char):
  return c == char('\t') or c == char('\r') or c == char('\n') or c == char(' ')

def isDelimiter(c as char):
  return c == kLPar or c == kRPar or c == kQuote or isSpace(c)

def skipSpaces(s as string):
  for i in range(len(s)):
    if not isSpace(s[i]):
      return s[i:]
  return ''

def makeNumOrSym(s as string):
  try:
    return Num(Int32.Parse(s))
  except e:
    return makeSym(s)

def readAtom(s as string):
  next = ''
  for i in range(len(s)):
    if isDelimiter(s[i]):
      next = s[i:]
      s = s[:i]
      break
  return ParseState(makeNumOrSym(s), next)

def parseError(s as string):
  return ParseState(s, '')

def read(s as string) as ParseState:
  s = skipSpaces(s)
  if len(s) == 0:
    return parseError('empty input')
  elif s[0] == kRPar:
    return parseError('invalid syntax: ' + s)
  elif s[0] == kLPar:
    s = s[1:]
    ret as object = kNil
    while true:
      s = skipSpaces(s)
      if len(s) == 0:
        return parseError('unfinishde parenthesis')
      elif s[0] == kRPar:
        break
      tmp = read(s)
      if tmp.elm.GetType() == Error:
        return tmp
      ret = Cons(tmp.elm, ret)
      s = tmp.next
    return ParseState(nreverse(ret), s[1:])
  elif s[0] == kQuote:
    tmp = read(s[1:])
    return ParseState(Cons(sym_quote, Cons(tmp.elm, kNil)), tmp.next)
  else:
    return readAtom(s)

def findVar(sym, env as object):
  while env.GetType() == Cons:
    alist = safeCar(env)
    while alist.GetType() == Cons:
      cell = toCons(alist)
      if safeCar(cell.car) == sym:
        return cell.car
      alist = cell.cdr
    env = safeCdr(env)
  return kNil

g_env = Cons(kNil, kNil)

def addToEnv(sym, val, env as object):
  toCons(env).car = Cons(Cons(sym, val), toCons(env).cdr)

def eval(obj as object, env):
  type = obj.GetType()
  if type == Nil or type == Num or type == Error:
    return obj
  elif type == Sym:
    bind = findVar(obj, env)
    if bind == kNil:
      return Error(toSym(obj).data + ' has no value')
    else:
      return toCons(bind).cdr
  return Error('noimpl')

addToEnv(sym_t, sym_t, g_env)

while true:
  System.Console.Write('> ')
  line = Console.ReadLine()
  if not line:
    break
  print(eval(read(line).elm, g_env).ToString())
