return function(H6x)
	local sandbox = H6x.Sandbox.new()

	local proxy = {
		BlockMe = newproxy(false);
		AllowMe = newproxy(false);
	}

	sandbox:AddRule({
		Rule = "Proxy";
		Mode = "ByReference";
		Target = proxy;

		ProxyRules = {
			{
				Rule = "Block";
				Mode = "ByReference";
				Target = proxy.BlockMe;
			};
			{
				Rule = "Allow";
				Mode = "ByReference";
				Target = proxy.AllowMe;
			};
			{ -- Terminate after allow (allow should skip this rule)
				Rule = "Terminate";
				Mode = "ByReference";
				Target = proxy.AllowMe;
			};
		};
	})

	sandbox:ExecuteFunction(function(proxy, source)
		assert(not proxy.BlockMe, "Did not block on Proxy rule.")
		assert(proxy.AllowMe, "Did not allow on Proxy rule.")
		assert(source.BlockMe, "Proxy rule applied to non-proxy source.")
		assert(type(proxy) == 'table', "Proxy is not a table.")
	end, proxy, {BlockMe = proxy.BlockMe})
end