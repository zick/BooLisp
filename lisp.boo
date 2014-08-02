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
    return '<error: ' + data + '>'

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

class Subr:
  public data as int
  def constructor(n as int):
    data = n
  def ToString():
    return "<subr>"

class Expr:
  public args as object
  public body as object
  public env as object
  def constructor(a, b, e):
    args = a
    body = b
    env = e
  def ToString():
    return "<epxr>"

class ParseState:
  public elm as object
  public next as string
  def constructor(o, s):
    elm = o
    next = s

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
def toSubr(obj):
  ret = obj cast Subr
  return ret
def toExpr(obj):
  ret = obj cast Expr
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
sym_if = makeSym('if')
sym_lambda = makeSym('lambda')

def safeCar(obj as object):
  if obj.GetType() == Cons:
    return toCons(obj).car
  return kNil

def safeCdr(obj as object):
  if obj.GetType() == Cons:
    return toCons(obj).cdr
  return kNil

def makeExpr(args, env):
  return Expr(safeCar(args), safeCdr(args), env)

def nreverse(lst as object):
  ret as object = kNil
  while lst.GetType() == Cons:
    cell = toCons(lst)
    tmp = cell.cdr
    cell.cdr = ret
    ret = lst
    lst = tmp
  return ret

def pairlis(lst1 as object, lst2 as object):
  ret as object = kNil
  while lst1.GetType() == Cons and lst2.GetType() == Cons:
    cell1 = toCons(lst1)
    cell2 = toCons(lst2)
    ret = Cons(Cons(cell1.car, cell2.car), ret)
    lst1 = cell1.cdr
    lst2 = cell2.cdr
  return nreverse(ret)

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
  toCons(env).car = Cons(Cons(sym, val), toCons(env).car)

def subrCall(id, args):
  if id == 0:
    return safeCar(safeCar(args))
  elif id == 1:
    return safeCdr(safeCar(args))
  elif id == 2:
    return Cons(safeCar(args), safeCar(safeCdr(args)))
  else:
    return Error('unknown subr')

def eval(obj as object, env as object) as object:
  type = obj.GetType()
  if type == Nil or type == Num or type == Error:
    return obj
  elif type == Sym:
    bind = findVar(obj, env)
    if bind == kNil:
      return Error(toSym(obj).data + ' has no value')
    else:
      return toCons(bind).cdr
  op = safeCar(obj)
  args = safeCdr(obj)
  if op == sym_quote:
    return safeCar(args)
  elif op == sym_if:
    c = eval(safeCar(args), env)
    if c.GetType() == Error:
      return c
    elif c == kNil:
      return eval(safeCar(safeCdr(safeCdr(args))), env)
    else:
      return eval(safeCar(safeCdr(args)), env)
  elif op == sym_lambda:
    return makeExpr(args, env)

  // evlis
  aargs as object = kNil
  lst as object = args
  while lst.GetType() == Cons:
    cell = toCons(lst)
    elm = eval(cell.car, env)
    if elm.GetType() == Error:
      aargs = elm
      break
    aargs = Cons(elm, aargs)
    lst = cell.cdr
  if aargs.GetType() != Error:
    aargs = nreverse(aargs)

  // apply
  fn = eval(op, env)
  type = fn.GetType()
  if type == Error:
    return fn
  elif aargs.GetType() == Error:
    return aargs
  elif type == Subr:
    return subrCall(toSubr(fn).data, aargs)
  elif type == Expr:
    // progn
    ret as object = kNil
    expr = toExpr(fn)
    body as object = expr.body
    env = Cons(pairlis(expr.args, aargs), expr.env)
    while body.GetType() == Cons:
      cell = toCons(body)
      ret = eval(cell.car, env)
      body = cell.cdr
    return ret
  else:
    return Error(fn.ToString() + ' is not function')

addToEnv(sym_t, sym_t, g_env)
addToEnv(makeSym('car'), Subr(0), g_env)
addToEnv(makeSym('cdr'), Subr(1), g_env)
addToEnv(makeSym('cons'), Subr(2), g_env)

while true:
  System.Console.Write('> ')
  line = Console.ReadLine()
  if not line:
    break
  print(eval(read(line).elm, g_env).ToString())
