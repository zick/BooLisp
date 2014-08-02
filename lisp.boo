import System

class Nil:
  pass

class Num:
  public data as int
  def constructor(n as int):
    data = n

class Sym:
  public data as string
  def constructor(s as string):
    data = s

class Error:
  public data as string
  def constructor(s as string):
    data = s

def toNum(obj):
  ret = obj cast Num
  return ret
def toSym(obj):
  ret = obj cast Sym
  return ret
def toError(obj):
  ret = obj cast Error
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
  return makeNumOrSym(s), next

def read(s as string):
  s = skipSpaces(s)
  if len(s) == 0:
    return Error('empty input'), ''
  elif s[0] == kRPar:
    return Error('invalid syntax: ' + s), ''
  elif s[0] == kLPar:
    return Error('noimpl'), ''
  elif s[0] == kQuote:
    return Error('noimpl'), ''
  else:
    return readAtom(s)

def printObj(obj):
  type = obj.GetType()
  if type == Nil:
    return 'nil'
  elif type == Num:
    return toNum(obj).data.ToString()
  elif type == Sym:
    return toSym(obj).data
  elif type == Error:
    return '<error: ' + toError(obj).data + '>'

while true:
  System.Console.Write('> ')
  line = Console.ReadLine()
  if not line:
    break
  print printObj(read(line)[0])
