class Owhat2Record < ActiveRecord::Base
	establish_connection :owhat2
end
$connection = Owhat2Record.establish_connection :owhat2
