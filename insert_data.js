db.orders.insertMany([
  { order_id: 1, customer: "Rahul Sharma",  product: "Laptop",     amount: 75000, status: "delivered", city: "Delhi" },
  { order_id: 2, customer: "Priya Singh",   product: "Phone",      amount: 25000, status: "pending",   city: "Mumbai" },
  { order_id: 3, customer: "Amit Kumar",    product: "Tablet",     amount: 35000, status: "delivered", city: "Bangalore" },
  { order_id: 4, customer: "Sneha Gupta",   product: "Headphones", amount: 5000,  status: "cancelled", city: "Pune" },
  { order_id: 5, customer: "Rohan Verma",   product: "Monitor",    amount: 18000, status: "delivered", city: "Hyderabad" },
  { order_id: 6, customer: "Neha Joshi",    product: "Keyboard",   amount: 3000,  status: "pending",   city: "Chennai" },
  { order_id: 7, customer: "Vikram Rao",    product: "Mouse",      amount: 1500,  status: "delivered", city: "Kolkata" },
  { order_id: 8, customer: "Pooja Mehta",   product: "Webcam",     amount: 4000,  status: "delivered", city: "Delhi" },
  { order_id: 9, customer: "Arjun Patel",   product: "SSD",        amount: 8000,  status: "pending",   city: "Mumbai" },
  { order_id: 10, customer: "Kavya Reddy",  product: "RAM",        amount: 6000,  status: "delivered", city: "Bangalore" },
  { order_id: 11, customer: "Dev Nair",     product: "CPU",        amount: 22000, status: "cancelled", city: "Pune" },
  { order_id: 12, customer: "Isha Kapoor",  product: "GPU",        amount: 55000, status: "delivered", city: "Delhi" },
  { order_id: 13, customer: "Karan Malhotra", product: "Speaker",  amount: 9000,  status: "pending",   city: "Jaipur" },
  { order_id: 14, customer: "Anjali Das",   product: "Printer",    amount: 12000, status: "delivered", city: "Lucknow" },
  { order_id: 15, customer: "Suresh Iyer",  product: "Router",     amount: 3500,  status: "delivered", city: "Chennai" }
]);
print("Documents count: " + db.orders.countDocuments());
