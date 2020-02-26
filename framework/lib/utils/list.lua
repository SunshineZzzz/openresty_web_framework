-- 封装对双向链表的操作

local type = type
local setmetatable = setmetatable

local List = {}
List.__index = List

-- == operator
-- 没有递归比较，后面再说
List.__eq = function(l1, l2)
	if type(l1) ~= type(l2) then
		return false
	end

	if l1:len() ~= l2:len() then
		return false
	end

	local ptr1 = l1.head
	local ptr2 = l2.head

	while ptr1 ~= nil do
		if ptr1.data ~= ptr2.data then
			return false
		end

		ptr1 = ptr1.next
		ptr2 = ptr2.next
	end

	return true
end

-- 打印
-- 简单类型，table啥的就算了吧
List.__tostring = function(self)
	local str = "-----\n"
	str = str .. "len = " .. tostring(self:len()) .. "\n"
	self:reset()
	for v in self:iterator() do
		str = str .. " " .. tostring(v) .. "\n"
	end
	str = str .. "-----"

	return str
end

-- node
local Node = {}
Node.__index = Node

-- 新建节点
function Node:new(data)
	self = {}
	setmetatable(self, Node)
	-- 数据
	self.data = data
	-- 下一个
	self.next = nil
	-- 上一个
	self.prev = nil

	return self
end

-- 创建一个空的list
function List:new()
	local self = {}
	setmetatable(self, List)

	-- 头结点
	self.head = nil
	-- 尾结点
	self.tail = nil
	-- 当前节点
	self.current = self.head
	-- 双向链表长度
	self._size = 0

	return self
end

-- 从数组table中构建list
function List:from_table(tbl)
	local list = List:new()

	for i=1, #t, 1 do
		list:push(t[i])
	end

	return list
end

-- 康康头
function List:peek_head()
	if self.head == nil then
		return nil
	end

	return self.head.data
end

-- 康康尾
function List:peek_tail()
	if self.tail == nil then
		return nil
	end

	return self.tail.data
end

-- 增加新元素
function List:push(element)
	local node = Node:new(element)

	if self:len() == 0 then
		self.head = node
		self.tail = node
		self.current = self.head
	else
		self.tail.next = node
		node.prev = self.tail
		self.tail = node
	end

	self._size = self:len() + 1
end

-- 弹出尾元素
function List:pop()
	if self.head == nil then
		return nil
	end

	local element = self.tail.data
	if self.head == self.tail then
		self.head = nil
		self.tail = nil
		self.current = self.head
	else
		local prev = self.tail.prev
		prev.next = nil
		self.tail = prev
	end

	self._size = self:len() - 1
	return element 
end

-- 头插入
function List:unshift(element)
	local node = Node:new(element)

	if self.head == nil then
		self.head = node
		self.tail = node
		self.current = self.head
	else
		self.head.prev = node
		node.next = self.head
		self.head = node
	end

	self._size = self:len() + 1
end

-- 移除头元素
function List:shift()
	if self.head == nil then
		return nil
	end

	local will_del_head = self.head
	local data = will_del_head.data

	if self.head == self.tail then
		self.head = nil
		self.tail = nil
	else
		local temp = self.head.next
		temp.prev = nil
		self.head.next = nil
		self.head = temp
	end

	if self.current == will_del_head then
		self.current = self.head
	end

	self._size = self:len() - 1

	return data
end

-- 指定位置前插入元素
function List:insert(index, element)
	assert(1 <= index and index <= self:len() + 1)

	-- 头插
	if index == 1 then
		self:unshift(element)
	-- 尾插
	elseif index == self:len() + 1 then
		self:push(element)
	-- 中间
	else
		local i = 1
		local prev = nil
		local curr = self.head

		while i < index do
			prev = curr
			curr = curr.next
			i = i + 1
		end

		local node = Node:new(element)

		curr.prev = node
		node.next = curr

		node.prev = prev
		prev.next = node

		self._size = self:len() + 1
	end
end

-- 康康长度
function List:len()
	return self._size
end

-- 重置current
function List:reset()
	self.current = self.head
end

function List:iterator()
	return function()
		if self.current == nil then
			return nil
		end

		local data = self.current.data
		self.current = self.current.next

		return data
	end	
end

return List


--[[
-- 无状态迭代器
function square(iteratorMaxCount, currentNumber)
	if currentNumber < iteratorMaxCount then
		currentNumber = currentNumber + 1
		return currentNumber, currentNumber*currentNumber
	end
end

function squares(iteratorMaxCount)
	return square, iteratorMaxCount, 0
end

-- for i,n in square, 10, 0
for i,n in squares(10) do
	print(i, n)
end

function iter(a, i)
	i = i + 1
	local v = a[i]
	if v then
		return i, v
	end
end

function ipairs(a)
	return iter, a, 0
end

-- 迭代函数、状态常量、控制变量
-- for k,v in iter, {"a", "b"}, 0
for k,v in ipairs({"a", "b"}) do
	print(k, v)
end

-- 有状态迭代器
function elementIterator(collection)
	local index = 0
	local count = #collection
	-- 闭包函数
	return function()
		index = index + 1
		if index <= count then
			return collection[index]
		end
	end
end

for element in elementIterator({a=1,b=2}}) do
	print(element)
end
]]