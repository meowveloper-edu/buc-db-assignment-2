// Switch to a specific database
use('my-new-database');

// drop fist
db.products.drop();
// Insert some documents into a 'products' collection
db.products.insertMany([
    { name: 'Laptop', price: 1200, in_stock: true },
    { name: 'Mouse', price: 25, in_stock: true }
]);

// Find all products to see the result
const allProducts = db.products.find();
// Print the results to the console

print("All products:");
printjson(allProducts.toArray());
