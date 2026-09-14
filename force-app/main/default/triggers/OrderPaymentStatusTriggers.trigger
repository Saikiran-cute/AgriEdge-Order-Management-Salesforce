trigger OrderPaymentStatusTriggers on AgriEdge_Order__c (after update) {

    Set<Id> orderIds = new Set<Id>();

    for (AgriEdge_Order__c order : Trigger.new) {

        AgriEdge_Order__c oldOrder = Trigger.oldMap.get(order.Id);

        if (order.Payment_Status__c == 'Paid'
            && oldOrder.Payment_Status__c != 'Paid'
            && order.Customer__c != null) {

            orderIds.add(order.Id);
        }
    }

    if (!orderIds.isEmpty()) {
        OrderEmailSender.sendOrderEmail(orderIds);
    }
}