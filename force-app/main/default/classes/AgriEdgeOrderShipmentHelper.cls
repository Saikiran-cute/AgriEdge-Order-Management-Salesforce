public class AgriEdgeOrderShipmentHelper {

    public static void processOrderStatusChange(
        List<AgriEdge_Order__c> updatedOrders
    ) {

        List<AgriEdge_Shipment__c> shipmentsToInsert =
            new List<AgriEdge_Shipment__c>();

        List<AgriEdge_Shipment__c> shipmentsToUpdate =
            new List<AgriEdge_Shipment__c>();

        List<AgriEdge_Order__c> ordersToUpdate =
            new List<AgriEdge_Order__c>();

        List<AgriEdge_OrderItem__c> orderItemsToDelete =
            new List<AgriEdge_OrderItem__c>();

        List<AgriEdge_Shipment__c> shipmentsToDelete =
            new List<AgriEdge_Shipment__c>();

        Set<Id> orderIds = new Set<Id>();

        for (AgriEdge_Order__c order : updatedOrders) {
            orderIds.add(order.Id);
        }

        // Find existing shipments
        Map<Id, AgriEdge_Shipment__c> existingShipments =
            new Map<Id, AgriEdge_Shipment__c>();

        for (AgriEdge_Shipment__c shipment : [
            SELECT Id, Order__c, Status__c
            FROM AgriEdge_Shipment__c
            WHERE Order__c IN :orderIds
        ]) {
            existingShipments.put(
                shipment.Order__c,
                shipment
            );
        }

        // Find existing order items
        Map<Id, List<AgriEdge_OrderItem__c>> existingOrderItems =
            new Map<Id, List<AgriEdge_OrderItem__c>>();

        for (AgriEdge_OrderItem__c orderItem : [
            SELECT Id, Order__c
            FROM AgriEdge_OrderItem__c
            WHERE Order__c IN :orderIds
        ]) {

            if (!existingOrderItems.containsKey(orderItem.Order__c)) {
                existingOrderItems.put(
                    orderItem.Order__c,
                    new List<AgriEdge_OrderItem__c>()
                );
            }

            existingOrderItems
                .get(orderItem.Order__c)
                .add(orderItem);
        }

        // Process orders
        for (AgriEdge_Order__c order : updatedOrders) {

            AgriEdge_Order__c updatedOrder =
                order.clone(false, true, false, false);

            updatedOrder.Id = order.Id;

            // Paid → Delivered
            if (
                order.Payment_Status__c == 'Paid'
                && order.Order_Status__c != 'Delivered'
            ) {
                updatedOrder.Order_Status__c = 'Delivered';
                ordersToUpdate.add(updatedOrder);
            }

            // Pending → Processing
            else if (order.Payment_Status__c == 'Pending') {
                updatedOrder.Order_Status__c = 'Processing';
                ordersToUpdate.add(updatedOrder);
            }

            // Failed → Canceled
            else if (order.Payment_Status__c == 'Failed') {

                updatedOrder.Order_Status__c = 'Canceled';
                ordersToUpdate.add(updatedOrder);

                if (existingOrderItems.containsKey(order.Id)) {
                    orderItemsToDelete.addAll(
                        existingOrderItems.get(order.Id)
                    );
                }

                if (existingShipments.containsKey(order.Id)) {
                    shipmentsToDelete.add(
                        existingShipments.get(order.Id)
                    );
                }
            }

            // Create shipment for Processing order
            if (
                order.Order_Status__c == 'Processing'
                && !existingShipments.containsKey(order.Id)
            ) {

                AgriEdge_Shipment__c newShipment =
                    new AgriEdge_Shipment__c(
                        Order__c = order.Id,
                        Tracking_Number__c = 'TEST_' + order.Id,
                        Status__c = 'Pending'
                    );

                shipmentsToInsert.add(newShipment);
            }

            // Update shipment for Shipped/Delivered
            else if (
                order.Order_Status__c == 'Shipped'
                || order.Order_Status__c == 'Delivered'
            ) {

                if (existingShipments.containsKey(order.Id)) {

                    AgriEdge_Shipment__c shipmentToUpdate =
                        existingShipments.get(order.Id);

                    shipmentToUpdate.Status__c =
                        (order.Order_Status__c == 'Shipped')
                        ? 'In Transit'
                        : 'Delivered';

                    shipmentsToUpdate.add(shipmentToUpdate);
                }
            }
        }

        // Update Orders
        if (!ordersToUpdate.isEmpty()) {
            update ordersToUpdate;
        }

        // Create Shipments
        if (!shipmentsToInsert.isEmpty()) {
            insert shipmentsToInsert;
        }

        // Update Shipments
        if (!shipmentsToUpdate.isEmpty()) {
            update shipmentsToUpdate;
        }

        // Delete Order Items
        if (!orderItemsToDelete.isEmpty()) {
            delete orderItemsToDelete;
        }

        // Delete Shipments
        if (!shipmentsToDelete.isEmpty()) {
            delete shipmentsToDelete;
        }
    }
}