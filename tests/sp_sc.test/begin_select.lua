local function main(test_no)
	db:begin()
	local statement0 = db:exec("SELECT sleep(2000)")
	if statement0 == nil then return db:error() end
	local consumer = db:consumer()
	consumer:get()
	consumer:consume()
	local statement1 = db:prepare("SELECT 'inner', s FROM t1 WHERE s = ?")
	if statement1 == nil then return db:error() end
	statement1:bind(1, tostring(test_no))
	local row1 = statement1:fetch()
	while row1 do
		db:emit(row1)
		row1 = statement1:fetch()
	end
	db:commit()
end
