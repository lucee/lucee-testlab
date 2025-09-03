component restPath="/api/products" {
	
	// Uses function name: GET /api/products/getProducts
	remote function getProducts() httpMethod="GET" {
		return {"message": "All products retrieved", "method": "getProducts"};
	}
	
	// Uses empty restPath: POST /api/products
	remote function addProduct() httpMethod="POST" restPath="" {
		return {"message": "Product added", "method": "addProduct"};
	}
	
	// Path parameter: GET /api/products/123
	remote function getProduct(string productID) httpMethod="GET" restPath="/{productID}" restArgSource="Path" {
		return {
			"message": "Single product retrieved",
			"productID": arguments.productID,
			"method": "getProduct"
		};
	}
	
	// URL parameters: GET /api/products/search?category=electronics&minPrice=100&maxPrice=500
	remote function searchProducts(
		string category = "" restArgSource="url",
		numeric minPrice = 0 restArgSource="url",
		numeric maxPrice = 999999 restArgSource="url",
		string sortBy = "name" restArgSource="url"
	) httpMethod="GET" restPath="/search" {
		return {
			"message": "Product search completed",
			"filters": {
				"category": arguments.category,
				"minPrice": arguments.minPrice,
				"maxPrice": arguments.maxPrice,
				"sortBy": arguments.sortBy
			},
			"method": "searchProducts"
		};
	}
	
	// Mixed: Path + URL parameters: GET /api/products/123/reviews?page=2&limit=10&rating=4
	remote function getProductReviews(
		string productID restArgSource="Path",
		numeric page = 1 restArgSource="url",
		numeric limit = 20 restArgSource="url",
		numeric rating = 0 restArgSource="url"
	) httpMethod="GET" restPath="/{productID}/reviews" {
		return {
			"message": "Product reviews retrieved",
			"productID": arguments.productID,
			"pagination": {
				"page": arguments.page,
				"limit": arguments.limit
			},
			"filters": {
				"rating": arguments.rating
			},
			"method": "getProductReviews"
		};
	}
	
	// URL parameters with function name: GET /api/products/getProductsByCategory?category=electronics&active=true
	remote function getProductsByCategory(
		string category restArgSource="url",
		boolean active = true restArgSource="url"
	) httpMethod="GET" {
		return {
			"message": "Products retrieved by category",
			"category": arguments.category,
			"activeOnly": arguments.active,
			"method": "getProductsByCategory"
		};
	}
	
	// Path parameter: PUT /api/products/123/status
	remote function updateProductStatus(string productID) httpMethod="PUT" restPath="/{productID}/status" restArgSource="Path" {
		return {
			"message": "Product status updated",
			"productID": arguments.productID,
			"method": "updateProductStatus"
		};
	}
	
	// Multiple URL parameters: GET /api/products/analytics?startDate=2024-01-01&endDate=2024-12-31&format=json&includeDeleted=false
	remote function getProductAnalytics(
		string startDate restArgSource="url",
		string endDate restArgSource="url",
		string format = "json" restArgSource="url",
		boolean includeDeleted = false restArgSource="url"
	) httpMethod="GET" restPath="/analytics" {
		return {
			"message": "Product analytics retrieved",
			"dateRange": {
				"start": arguments.startDate,
				"end": arguments.endDate
			},
			"options": {
				"format": arguments.format,
				"includeDeleted": arguments.includeDeleted
			},
			"method": "getProductAnalytics"
		};
	}
}