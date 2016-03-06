(function(express){
    "use strict";
    return express()
	.get("/", function(request, response){
	    return response.send("Hello World!");
	})
	.listen(3000)
    ;
}(require("express")));
