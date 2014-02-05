###
registers

0000 = zero
0001 = one
0010 = accu
0011 = register1
0100 = register2
0101 = register3
0110 = register4
0111 = register5
1111 = position (better not use this one!)

commands

1000 = <not yet planned>
1001 = LOADL from following to accu //for longer addresses if needed
1010 = SAVEL to following to accu //for longer addresses if needed
1011 = LOADR to reg1 from address
1100 = SAVER from reg2 to address
1101 = EQUALN values of reg1 and reg2 lead to a jump to pos+n
1110 = <not yet planned>
1111 = <not yet planned>

00000000 = QUIT
00000001 = LOAD from following to accu 
00000010 = SAVE to following to accu 
00000011 = ADD reg1 to reg2 and put value into accu
00000100 = SUB reg2 from reg1 and put value into accu
00000101 = JUMP to given address
00000110 = EQUAL values of reg1 and reg2 lead to a jump to position+2
00000111 = GREATER values of reg1 than reg2 lead to a jump to position+2
00001000 = SMALLER values of reg1 than reg2 lead to a jump to position+2
00001001 = INEQUAL values of reg1 and reg2 lead to a jump to position+2
00001010 = COPY value of reg1 into reg2
00001011 = MULTIPLY reg1 and reg2 and put value into accu
00001100 = SHIFTLEFT reg1 by n
00001101 = SHIFTRIGHT reg2 by n
00001110 = <not yet planned>
00001111 = <not yet planned>
00010000 = <not yet planned>
00010001 = <not yet planned>
00010010 = <not yet planned>
00010011 = <not yet planned>
00010100 = <not yet planned>
00010101 = <not yet planned>
00010110 = <not yet planned>
00010111 = <not yet planned>
00011000 = <not yet planned>
00011000 = <not yet planned>
00011001 = <not yet planned>
00011010 = <not yet planned>
00011011 = <not yet planned>
00011100 = <not yet planned>
00011101 = <not yet planned>
00011110 = <not yet planned>
00011111 = <not yet planned>
		     .
		     .
		     .
01111111 = <not yet planned>

###



#+-----------------------------------------------+
#|                    OPTIONS                    |
#+-----------------------------------------------+

CELLSIZE = 16
MEMORYSIZE = 64
MEMORYADDRESSSPACE = 8
HARDDISKSIZE = 1024
PAGESIZE = CELLSIZE * MEMORYSIZE/2

#+-----------------------------------------------+
#|                    HELPER                     |
#+-----------------------------------------------+

root = exports ? this

type = (obj) ->
	if obj == undefined or obj == null
		return String obj
	classToType = 
	'[object Boolean]': 'boolean',
	'[object Number]': 'number',
	'[object String]': 'string',
	'[object Function]': 'function',
	'[object Array]': 'array',
	'[object Date]': 'date',
	'[object RegExp]': 'regexp',
	'[object Object]': 'object'

	return classToType[Object.prototype.toString.call(obj)]

dec2Bin = (dec, length) ->
	out = ""
	(out += (dec >> length ) & 1) while length--
	return out

bin2Dec = (bin) ->
	out = 0;
	for i in [0..bin.length-1]
		char = bin.charAt(bin.length - 1 - i)
		value = if char is "1" then 1 else 0
		out += Math.pow(2, i) * value
	out

fitLength = (string, desiredLength, fillSymbol = " ", inEnd = true) ->
	difference = desiredLength - string.length

	console.error("#{string} string is longer than desiredLength") if difference < 0
	return string if difference is 0

	appendix = ""
	appendix += fillSymbol for i in [1..difference]
	if inEnd then string + appendix else appendix + string

root.compileToAssembler = (string, debug = false) ->
	result = []
	lines = string.split "\n"

	console.log "converting code: " if debug

	for line in lines
		#replace literal commands
		line = line.replace /LOADL/g, "1001"
		line = line.replace /SAVEL/g, "1010"
		line = line.replace /LOADR/g, "1011"
		line = line.replace /SAVER/g, "1100"
		line = line.replace /EQUALN/g, "1101"
		line = line.replace /ZERO/g, "0000000000000000"
		line = line.replace /EMPTY/g, "00000000"
		line = line.replace /QUIT/g, "00000000" 
		line = line.replace /LOAD/g, "00000001"  
		line = line.replace /SAVE/g, "00000010"  
		line = line.replace /ADD/g, "00000011"  
		line = line.replace /SUB/g, "00000100"  
		line = line.replace /JUMP/g, "00000101"  
		line = line.replace /EQUAL/g, "00000110"  
		line = line.replace /GREATER/g, "00000111"  
		line = line.replace /SMALLER/g, "00001000"  
		line = line.replace /UNEQUAL/g, "00001001"  
		line = line.replace /COPY/g, "00001010"
		line = line.replace /MULTIPLY/g, "00001011"
		line = line.replace /MUL/g, "00001011"
		line = line.replace /SHIFTLEFT/g, "00001100"
		line = line.replace /SHIFTRIGHT/g, "00001101"
		#remove spaces
		line = line.replace /\s/g, ''
		#remove comments
		split = line.split '#', 1
		line = split[0]
		console.log line if debug
		if line.length isnt 0
			result.push line
	console.log " " if debug
	result

#+-----------------------------------------------+
#|                     CODE                      |
#+-----------------------------------------------+

#
#                      CELL
#

class Cell
	constructor: (locked = false) ->
		@locked = locked
		@content = []
		@content.push(false) for i in [0..CELLSIZE-1]

	getContent: () =>
		@content

	getAsBinary: () =>
		result = ""
		result += (if i then "1" else "0") for i in @content
		result

	getAddress: () =>
		result = ""
		for i in @content[8..15]
			result += (if i then "1" else "0") 
		result

	getBeautiful: () =>
		result = ""
		counter = 0
		for i in @content
			if counter is 8
				counter = 0
				result += " "
			result += (if i then "1" else "0")
			counter++
		result

	setFromBinary: (string) =>
		if @locked 
			console.error "CELL ERROR: tried to write to locked cell"
			return

		if type(string) isnt "string"
			console.error "CELL ERROR: type of input must be string"
			return

		if string.length isnt CELLSIZE
			console.error "CELL ERROR: wrong input length"
			return

		tmp = @content.slice 0

		for i in [0..CELLSIZE-1]
			bitValue = string.charAt(i);

			if bitValue is "0"
				@content[i] = false
			else if bitValue is "1"
				@content[i] = true
			else
				console.error "CELL ERROR: input must only contain 1 and 0"
				@content = tmp
				return

	setContent: (array) =>
		if @locked 
			console.error "CELL ERROR: tried to write to locked cell"
			return

		if type(array) isnt "array"
			console.error "CELL ERROR: type of input must be array"
			return

		if array.length isnt CELLSIZE
			console.error "CELL ERROR: wrong input length"
			return

		for i in [0..CELLSIZE-1]
			bitValue = array[i]

			if type(bitValue) isnt "boolean"
				console.error "CELL ERROR: input must be boolean only array"
				return

		@content = array.slice 0

	shiftLeft: (n) =>
		if n >= MEMORYSIZE
			@content = [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false]
			return
		for i in [0..n]
			@content.push false
			@content.shift()

	shiftRight: (n) =>
		if n >= MEMORYSIZE
			@content = [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false]
			return
		for i in [0..n]
			@content.unshift false
			@content.pop()

#	fastSetFromBinary: (string) =>
#		for i in [string.length-1.0]
#			if string.charAt(i) is "0"
#				@content[CELLSIZE-1-string.length+i] = false
#			else
#				@content[CELLSIZE-1-string.length+i] = true


	getValue: () =>
		result = 0;
		for i in [1..CELLSIZE]
			value = if @content[CELLSIZE - i] then 1 else 0
			result += Math.pow(2, i - 1) * value
		result

	setValue: (value) =>
		if @locked 
			console.error "CELL ERROR: tried to write to locked cell"
			return

		@setFromBinary(dec2Bin(value, CELLSIZE))

	lock: () =>
		@locked = true

#
#                     MEMORY
#

class Memory 
	constructor: (size = MEMORYSIZE) ->
		@size = size
		@alias = []
		@cells = []
		@cells.push(new Cell()) for i in [0..size-1]		
		for cell, i in @cells
			@alias[dec2Bin(i, MEMORYADDRESSSPACE)] = cell

	printMemoryAsBinary: () ->
		fittingLength = @size.toString().length + 1
		console.log(fitLength("" + i, fittingLength) + ": " + cell.getBeautiful()) for cell, i in @cells

	setFromBinaryArray: (array) =>
		if type(array) isnt "array"
			console.error "MEMORY ERROR: input type must be array"
			return

		if array.length > @size
			console.error "MEMORY ERROR: input array must not be longer than memory"
			return;

		@setFromBinaryAt(i, string) for string, i in array

	setValueAt: (position, value) =>
		if position < 0 or position >= MEMORYSIZE
			console.error "MEMORY ERROR: position not in Memory"
			return

		@cells[position].setValue(value)

	setFromBinaryAt: (position, string) =>
		if position < 0 or position >= MEMORYSIZE
			console.error "MEMORY ERROR: position not in Memory"
			return

		@cells[position].setFromBinary(string)

	setContentAt: (position, content) =>
		if position < 0 or position >= MEMORYSIZE
			console.error "MEMORY ERROR: position not in Memory"
			return

		@cells[position].setContent(content);

	getValueAt: (position) =>
		if position < 0 or position >= MEMORYSIZE
			console.error "MEMORY ERROR: position not in Memory"
			return

		@cells[position].getValue()

	getContentAt: (position) =>
		if position < 0 or position >= MEMORYSIZE
			console.error "MEMORY ERROR: position not in Memory"
			return

		@cells[position].getContent()

	getAsBinaryAt: (position) =>
		if position < 0 or position >= MEMORYSIZE
			console.error "MEMORY ERROR: position not in Memory"
			return

		@cells[position].getAsBinary()

	setValue: (position, value) =>
		cell = null
		cell ?= @alias[position]
		console.log cell
		if not cell?
			console.error "MEMORY ERROR: position not in Memory"
			return

		cell.setValue(value)

	setFromBinary: (position, string) =>
		cell = null
		cell ?= @alias[position]
		console.log cell
		if not cell?
			console.error "MEMORY ERROR: position not in Memory"
			return

		cell.setFromBinary(string)

	setContent: (position, content) =>
		cell = null
		cell ?= @alias[position]
		console.log cell
		if not cell?
			console.error "MEMORY ERROR: position not in Memory"
			return

		cell.setContent(content);

	getValue: (position) =>
		cell = null
		cell ?= @alias[position]
		console.log cell
		if not cell?
			console.error "MEMORY ERROR: position not in Memory"
			return

		cell.getValue()

	getContent: (position) =>
		cell = null
		cell ?= @alias[position]
		console.log cell
		if not cell?
			console.error "MEMORY ERROR: position not in Memory"
			return

		cell.getContent()

	getAsBinary: (position) =>
		cell = null
		cell ?= @alias[position]
		console.log cell
		if not cell?
			console.error "MEMORY ERROR: position not in Memory"
			return

		cell.getAsBinary()

	getBeautiful: (position) =>
		cell = null
		cell ?= @alias[position]
		console.log cell
		if not cell?
			console.error "MEMORY ERROR: position not in Memory"
			return

		cell.getBeautiful()

	getBeautifulAt: (position) =>
		if position < 0 or position >= MEMORYSIZE
			console.error "MEMORY ERROR: position not in Memory"
			return

		@cells[position].getBeautiful()


#
#                    HARDDISK
#

class Harddisk
	constructor: (size = HARDDISKSIZE, pagesize = PAGESIZE) ->

#
#                   CONTROLLER
#

class Controller
	constructor: () ->
		@running = false
		@memory = new Memory()
		@accu = new Cell()
		@position = new Cell()
		@register1 = new Cell()
		@register2 = new Cell()
		@register3 = new Cell()
		@register4 = new Cell()
		@register5 = new Cell()
		@zero = new Cell(true)
		@one = new Cell()
		@one.setValue(1)
		@one.lock()

	loadMemoryFromArray: (array) =>
		@memory.setFromBinaryArray(array)

	emptyRegisters: () =>
		@accu.setContent @zero.getContent()
		@position.setContent @zero.getContent()
		@register1.setContent @zero.getContent()
		@register2.setContent @zero.getContent()
		@register3.setContent @zero.getContent()
		@register4.setContent @zero.getContent()
		@register5.setContent @zero.getContent()

	run: (start = 0, debug = false) =>
		if debug
			oldtime = (new Date).getTime()
		if start < 0 or start >= MEMORYSIZE
			console.error "CONTROLLER ERROR: startposition must be in memory"
			return;
		if start isnt 0
			@position.setValue(start)

		@running = true;

		if debug
			console.log " "
			console.log "Debug data from run of Controller: "
			console.log " "


		while @running
			@doTick(debug)

		if debug
			@printStatus()
			console.log " "
			console.log "Programm took: " + ((new Date).getTime() - oldtime) + "ms to run"

	getRegister: (register) =>
		switch register
			when "0000" then @zero
			when "0001" then @one
			when "0010" then @accu
			when "0011" then @register1
			when "0100" then @register2
			when "0101" then @register3
			when "0110" then @register4
			when "0111" then @register5
			when "1111" then @position
			else
				console.error "CONTROLLER ERROR: given register #{register} is not existing"
				@running = false
				return

	printStatus: () =>
		console.log " "
		console.log if @running then "Controller is running" else "Controller is not running"
		console.log " "
		console.log "Registers:"
		console.log " "
		console.log "accu : " + @accu.getBeautiful()
		console.log "register1 : " + @register1.getBeautiful()
		console.log "register2 : " + @register2.getBeautiful()
		console.log "register3 : " + @register3.getBeautiful()
		console.log "register4 : " + @register4.getBeautiful()
		console.log "position : " + @position.getBeautiful()
		console.log "zero : " + @zero.getBeautiful() +  " warning this must alway be the equal of 0, if its not bad things WILL happen"
		console.log "one : " + @one.getBeautiful() + " warning this must alway be the equal of 1, if its not bad things WILL happen"
		console.log " "
		console.log "Memory:"
		console.log " "
		@memory.printMemoryAsBinary();

	doTick: (debug = false) =>
		pos = @position.getValue()
		if debug
			console.log " "
			console.log "tick:" 
			console.log "position: " + pos

		if 0 < pos >= MEMORYSIZE
			console.error "CONTROLLER ERROR: position is not in memory"
			@running = false
			return

		tmp = @memory.getAsBinaryAt(pos)
		console.log "processing: " + @memory.getBeautifulAt(pos) if debug
		cmd = ""
		arg = ""

		if tmp.charAt(0) is "1"
			cmd = tmp.slice(0, 4)
			arg = tmp.slice(4)
		else
			cmd = tmp.slice(0, 8)
			arg = tmp.slice(8)

		console.log "split to #{cmd} and #{arg}" if debug

		switch cmd
			when "00000000"
				console.log "QUIT" if debug
				@running = false
			when "1001", "00000001"
				console.log "LOAD to accu from #{arg} (#{bin2Dec(arg)})" if debug
				@accu.setContent(@memory.getContent(arg))
			when "1010", "00000010"
				console.log "SAVE from accu to #{arg} (#{bin2Dec(arg)})" if debug
				@memory.setContent(arg, @accu.getContent())
			when "1011"
				reg = arg.slice(0, 4)
				position = arg.slice(4)
				console.log "LOAD to reg (#{reg}) from #{position} (#{bin2Dec(position)})" if debug
				@getRegister(reg).setContent(@memory.getContent(position));
			when "1100"
				reg = arg.slice(0, 4)
				position = arg.slice(4)
				console.log "SAVE from reg (#{reg}) to #{position} (#{bin2Dec(position)})" if debug
				@memory.setContent(position, @getRegister(reg).getContent());
			when "1101"
				reg1 = arg.slice(0, 4)
				reg2 = arg.slice(4, 8)
				n = arg.slice(8)
				console.log "EQUAL values of reg1 (#{reg1}) and reg2 (#{reg2}) lead to a relative jump of n (#{bin2Dec(n)})" if debug
				if @getRegister(reg1).getValue() is @getRegister(reg2).getValue()
					@position.setValue(@position.getValue() + bin2Dec(n) - 1)
			when "00000011"
				reg1 = arg.slice(0, 4)
				reg2 = arg.slice(4)
				console.log "ADD reg1 (#{reg1}) and reg2 (#{reg2}) and save to accu" if debug
				@accu.setValue @getRegister(reg1).getValue() + @getRegister(reg2).getValue()
			when "00000100"
				reg1 = arg.slice(0, 4)
				reg2 = arg.slice(4)
				console.log "SUB reg2 (#{reg2}) from reg1 (#{reg1}) and save to accu" if debug
				@accu.setValue @getRegister(reg1).getValue() - @getRegister(reg2).getValue()
			when "00000101"
				console.log "JUMP to position #{arg} (#{bin2Dec(arg)})" if debug
				@position.setFromBinary(fitLength(arg, 16, "0", false))
				return
			when "00000110"
				reg1 = arg.slice(0, 4)
				reg2 = arg.slice(4)
				console.log "EQUAL values of reg1 (#{reg1}) and reg2 (#{reg2}) lead to a relative jump of 2" if debug
				if @getRegister(reg1).getValue() is @getRegister(reg2).getValue()
					@position.setValue(@position.getValue() + 1)
			when "00000111"
				reg1 = arg.slice(0, 4)
				reg2 = arg.slice(4)
				console.log "GREATER values of reg1 (#{reg1}) than reg2 (#{reg2}) lead to a relative jump of 2" if debug
				if @getRegister(reg1).getValue() > @getRegister(reg2).getValue()
					@position.setValue(@position.getValue() + 1)
			when "00001000"
				reg1 = arg.slice(0, 4)
				reg2 = arg.slice(4)
				console.log "SMALLER values of reg1 (#{reg1}) than reg2 (#{reg2}) lead to a relative jump of 2" if debug
				if @getRegister(reg1).getValue() < @getRegister(reg2).getValue()
					@position.setValue(@position.getValue() + 1)
			when "00001001"
				reg1 = arg.slice(0, 4)
				reg2 = arg.slice(4)
				console.log "UNEQUAL values of reg1 (#{reg1}) than reg2 (#{reg2}) lead to a relative jump of 2" if debug
				if @getRegister(reg1).getValue() isnt @getRegister(reg2).getValue()
					@position.setValue(@position.getValue() + 1)
			when "00001010"
				reg1 = arg.slice(0, 4)
				reg2 = arg.slice(4)
				console.log "COPY values of reg1 (#{reg1}) into reg2(#{reg2})" if debug
				@getRegister(reg2).setContent(@getRegister(reg1).getContent())
			when "00001011"
				reg1 = arg.slice(0, 4)
				reg2 = arg.slice(4)
				console.log "MULTIPLY reg1 (#{reg1}) and reg2 (#{reg2}) and save to accu" if debug
				@accu.setValue @getRegister(reg1).getValue() * @getRegister(reg2).getValue()
			when "00001100"
				reg1 = arg.slice(0, 4)
				n = arg.slice(4)
				console.log "SHIFTLEFT reg1 (#{reg1}) by n (#{bin2Dec(n)})" if debug
				@getRegister(reg1).shiftLeft(bin2Dec(n))
			when "00001101"
				reg1 = arg.slice(0, 4)
				n = arg.slice(4)
				console.log "SHIFTRIGHT reg1 (#{reg1}) by n (#{bin2Dec(n)})" if debug
				@getRegister(reg1).shiftRight(bin2Dec(n))
			else
				console.error "CONTROLLER ERROR: this command #{cmd} is not known"
				@running = false
				return

		@position.setValue(@position.getValue() + 1)

root.Controller = Controller
root.Memory = Memory
root.Cell = Cell

#cont = new Controller()
#cont.loadMemoryFromArray [
#	"1011001100000111", #load n into 0011
#	"1011010000001000", #load m into 0100
#	"1101001101000010", #compare 0011 and 0100
#	"0000010100000101", #jump to 5
#	"0000000000000000", #QUIT
#	"1100001100001000", #save too m
#	"1011010000001000", #reload m into 0100
#	"0000000000000010", #n
#	"0000000000000001"  #m
#]
#cont.run(0, true)