const kind = token => 
  typeof(token) !== 'string' ? undefined :
  ['+', '-'].includes(token) ? 'OPERATOR':
  token.match(/^\d+$/)       ? 'NUMBER'  :
  token.match(/^\d+d\d+$/)   ? 'DICE'    :
  undefined

const parse = source => {
  const stack = []
  const result = []
  source.match(/([+-])|(\d+d\d+)|(\d+)/ig).forEach(token => {
    if(kind(token) === 'OPERATOR') {
      if(stack.length !== 0) result.push(stack.pop())
      stack.push(token)
    }else if(['NUMBER', 'DICE'].includes(kind(token))){
      result.push(token)
    }
  })
  return result.concat(stack.reverse())
}

const make_tree = arr => {
  const stack = []
  arr.forEach(token => {
    if(['NUMBER', 'DICE'].includes(kind(token))) stack.push(token)
    if(kind(token) === 'OPERATOR') stack.push([token, stack.pop(), stack.pop()])
  })
  return stack[0]
}

const calc = expression => {
  if(kind(expression) === 'DICE') return roll(expression)
  if(kind(expression) === 'NUMBER') return parseInt(expression) 
  const [ope, left, right] = expression
  switch(ope) {
    case '+': return calc(left) + calc(right)
    case '-': return calc(left) - calc(right)
  }
}

const roll = str => {
  const m = str.match(/(\d+)d(\d+)/i)
  dices = parseInt(m[1], 10) // number of dices
  faces = parseInt(m[2], 10) // number of dice faces
  if(dices < 1 || dices > 1000) throw 'ダイスの数は1～1000'
  if(faces < 1 || faces > 1000) throw '面の数は1～1000'
  const range = function* (from, to) {
    for(let i=from; i<=to; i++) yield i
  }
  const eyes = Array.from(range(1, dices)).map(() => Math.floor(Math.random() * faces) + 1)
  return eyes.reduce((l,r) => l + r)
}

const exec = source => {
  try {
    tree = make_tree(parse(source))
    console.log(tree)
    if(tree.includes(undefined)) throw '何かがおかしいです…'
    return calc(tree)
  } catch(error) {
    console.error(error.stack)
    return `エラー！ ${error}`
  }
}

const debug = (source, option) => {
  if(!option['debug']) return ''
  try {
    out = "```\n#DEBUG\n"
    out += `入力   [${JSON.stringify(source)}]\n`
    parsed = parse(source)
    out += `逆ポ   ${JSON.stringify(parsed)}\n`
    tree = make_tree(parsed)
    out += `構文木 ${JSON.stringify(tree)}\n`
    result = calc(tree)
    out += `結果   [${JSON.stringify(result)}]`
  } catch(error) {
    out += `ここでエラー！\n${error}\n`
  } finally {
    out += "```\n"
  }
  return out
}

module.exports = robot => {
  robot.respond(/(.*)/, msg => {
    input = msg.match[1]
    const m = input.match(/(\d+d\d+|\d+|[+-]| +)+/i)
    if(!m) return
    source = m[0].trim().replace(/\s+/g, ' ')
    option = {}
    option['debug'] = !!input.match(/\bdebug\b/)
    msg.send(`${source} -> ${exec(source, option)}`)
    if(option['debug']) msg.send(debug(source, option))
  })
}
