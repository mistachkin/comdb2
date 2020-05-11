local function main(test_no)
	db:begin()
	local statement0 = db:exec("SELECT sleep(abs(random() % 2))")
	if statement0 == nil then return db:error() end
	local row0 = statement0:fetch()
	if row0 == nil then return db:error() end
	local consumer = db:consumer()
	consumer:get()
	consumer:consume()
	local statement1 = db:prepare("INSERT INTO t1 VALUES(?)")
	if statement1 == nil then return db:error() end
	statement1:bind(1, tostring(test_no))
	local rc1 = statement1:exec()
	if rc1 ~= 0 then return db:error() end
	db:commit()
end
