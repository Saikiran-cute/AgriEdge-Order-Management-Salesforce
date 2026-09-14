trigger AgriEdgeOrderTrigger on AgriEdge_Order__c
    (after insert, after update) {

    // Prevent recursive execution
    if (AgriEdgeOrderTriggerHelper.isTriggerExecuted) {
        return;
    }

    AgriEdgeOrderTriggerHelper.isTriggerExecuted = true;

    try {

        List<AgriEdge_Order__c> ordersToProcess =
            new List<AgriEdge_Order__c>();

        for (AgriEdge_Order__c order : Trigger.new) {

            if (Trigger.isInsert) {
                ordersToProcess.add(order);
            }

            else if (Trigger.isUpdate) {

                AgriEdge_Order__c oldOrder =
                    Trigger.oldMap.get(order.Id);

                if (
                    order.Order_Status__c != oldOrder.Order_Status__c
                    ||
                    order.Payment_Status__c != oldOrder.Payment_Status__c
                ) {
                    ordersToProcess.add(order);
                }
            }
        }

        if (!ordersToProcess.isEmpty()) {
                AgriEdgeOrderShipmentHelper.processOrderStatusChange(ordersToProcess);
        }

    } finally {

        AgriEdgeOrderTriggerHelper.isTriggerExecuted = false;
    }
}