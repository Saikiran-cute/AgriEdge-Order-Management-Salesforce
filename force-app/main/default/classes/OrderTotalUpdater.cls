public class OrderTotalUpdater {

    public static void updateOrderTotal(Set<Id> orderIds) {

        if (orderIds == null || orderIds.isEmpty()) {
            return;
        }

        // Map to store Order Id and its Total Price
        Map<Id, Decimal> orderTotals = new Map<Id, Decimal>();

        // Query all Order Items related to the given Orders
        for (AggregateResult ar : [
            SELECT Order__c orderId,
                   SUM(Total_Price__c) totalAmount
            FROM AgriEdge_OrderItem__c
            WHERE Order__c IN :orderIds
            GROUP BY Order__c
        ]) {

            orderTotals.put(
                (Id) ar.get('orderId'),
                (Decimal) ar.get('totalAmount')
            );
        }

        List<AgriEdge_Order__c> ordersToUpdate =
            new List<AgriEdge_Order__c>();

        // Query Orders that need to be updated
        for (AgriEdge_Order__c order : [
            SELECT Id, Total_Amount__c, Payment_Status__c
            FROM AgriEdge_Order__c
            WHERE Id IN :orderIds
        ]) {

            // Update Total Amount
            order.Total_Amount__c =
                orderTotals.containsKey(order.Id)
                ? orderTotals.get(order.Id)
                : 0;

            // Update Payment Status
            order.Payment_Status__c =
                (order.Total_Amount__c > 0)
                ? 'Pending'
                : 'Paid';

            ordersToUpdate.add(order);
        }

        // Save changes
        if (!ordersToUpdate.isEmpty()) {
            update ordersToUpdate;
        }
    }
}