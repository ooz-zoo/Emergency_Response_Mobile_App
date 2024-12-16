const String stripePublishableKey =
    "pk_test_51Q8jrjEFUzL4oHRXyKmM8df8tJb7K72Q7uwyvHBgjbsRevACcBwH4XZGxBCySPlu4XPFAodD0038MQQV4lOEt1jE00KVucvs1m";
const String stripeSecretKey =
    "sk_test_51Q8jrjEFUzL4oHRXkbdH5GH2tmsg2C3Z2FmMFfeLb7V25YP1DNTr1kYaJ33FrkpuyVMDaTfKdJXr0sl7FCBWLU6400AjL0wbFu";

/* To maintain security purposes, in production mode 
Make sure the secret key is never exposed to end user
HOW DOES THE PAYMENT FLOW FOR STRIPE WORK?
Use secret key to create a payment intent(amount payment methods user can use)
Take the payment intent give it to client side call(flutter application)
 
Do the payment creation for the Payment intent logic on server (eg firebase), then the server creates the payment intent 
eg. use stripe secret key and payment creation logic, define a cloud function, invoke cloud function everytime a payment intent is required, then have payment intent returned to client side to display a payment form

return client secrer*/