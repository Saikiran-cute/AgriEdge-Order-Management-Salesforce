public class OrderEmailSender {

    public static void sendOrderEmail(Set<Id> orderIds) {

        if (orderIds == null || orderIds.isEmpty()) {
            return;
        }

        List<AgriEdge_Order__c> orders = [
            SELECT Id, Name, Customer__c,
                   Payment_Status__c
            FROM AgriEdge_Order__c
            WHERE Id IN :orderIds
        ];

        List<Messaging.SingleEmailMessage> emails =
            new List<Messaging.SingleEmailMessage>();

        for (AgriEdge_Order__c order : orders) {

            if (order.Customer__c == null) {
                continue;
            }

            List<Contact> contacts = [
                SELECT Id, Email
                FROM Contact
                WHERE AccountId = :order.Customer__c
                AND Email != null
            ];

            for (Contact contact : contacts) {

                Messaging.SingleEmailMessage email =
                    new Messaging.SingleEmailMessage();

                email.setToAddresses(
                    new List<String>{contact.Email}
                );

                email.setSubject(
                    'Order Payment Completed - ' + order.Name
                );

                email.setHtmlBody(
                    '<h2>Order Payment Completed</h2>' +
                    '<p>Your payment for order <b>' +
                    order.Name +
                    '</b> has been completed successfully.</p>' +
                    '<p>Thank you for your order.</p>'
                );

                emails.add(email);
            }
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}