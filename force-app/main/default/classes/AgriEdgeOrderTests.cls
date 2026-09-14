@isTest
public class AgriEdgeOrderTests {

    // ---------------------------------------------------------
    // Test OrderTaskCreator
    // ---------------------------------------------------------
    @isTest
    public static void testOrderTaskCreator() {

        Account testAccount = new Account(
            Name = 'Test Customer'
        );
        insert testAccount;

        // Get Platform 1 profile
        Profile platform1Profile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Platform 1'
            LIMIT 1
        ];

        User testUser = new User(
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Alias = 'tuser',
            ProfileId = platform1Profile.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        AgriEdge_Order__c order = new AgriEdge_Order__c(
            Payment_Status__c = 'Paid',
            Order_Status__c = 'Processing',
            Customer__c = testAccount.Id
        );
        insert order;

        Test.startTest();

        OrderTaskCreator.createTaskForNewOrder(
            new List<Id>{order.Id}
        );

        Test.stopTest();

        List<Task> tasks = [
            SELECT Id, WhatId, Subject, Priority, Status
            FROM Task
            WHERE WhatId = :order.Id
        ];

        // There are 2 Platform 1 users in the org/test context
        System.assertEquals(
            2,
            tasks.size(),
            'Two tasks should be created for the Platform 1 users.'
        );

        System.assertEquals(
            order.Id,
            tasks[0].WhatId,
            'Task should be linked to the correct order.'
        );

        System.assertEquals(
            'New Order Created',
            tasks[0].Subject,
            'Task subject should be New Order Created.'
        );

        System.assertEquals(
            'High',
            tasks[0].Priority,
            'Task priority should be High.'
        );
    }


    // ---------------------------------------------------------
    // Test OrderStatusUpdater
    // ---------------------------------------------------------
    @isTest
    public static void testOrderStatusUpdater() {

        AgriEdge_Order__c order1 = new AgriEdge_Order__c(
            Order_Status__c = 'New',
            Payment_Status__c = 'Pending'
        );
        insert order1;

        AgriEdge_Order__c order2 = new AgriEdge_Order__c(
            Order_Status__c = 'Processing',
            Payment_Status__c = 'Pending'
        );
        insert order2;

        AgriEdge_Order__c order3 = new AgriEdge_Order__c(
            Order_Status__c = 'Canceled',
            Payment_Status__c = 'Failed'
        );
        insert order3;

        Set<Id> orderIds = new Set<Id>{
            order1.Id,
            order2.Id,
            order3.Id
        };

        Test.startTest();

        OrderStatusUpdater.updateOrderStatus(orderIds);

        Test.stopTest();

        Map<Id, AgriEdge_Order__c> updatedOrders =
            new Map<Id, AgriEdge_Order__c>(
                [
                    SELECT Id, Order_Status__c
                    FROM AgriEdge_Order__c
                    WHERE Id IN :orderIds
                ]
            );

        System.assertEquals(
            'Processing',
            updatedOrders.get(order1.Id).Order_Status__c,
            'New order should become Processing.'
        );

        System.assertEquals(
            'Processing',
            updatedOrders.get(order2.Id).Order_Status__c,
            'Processing order should remain Processing.'
        );

        System.assertEquals(
            'Canceled',
            updatedOrders.get(order3.Id).Order_Status__c,
            'Canceled order should remain Canceled.'
        );
    }


    // ---------------------------------------------------------
    // Test OrderTotalUpdater
    // ---------------------------------------------------------
    @isTest
    public static void testOrderTotalUpdater() {

        AgriEdge_Order__c order1 = new AgriEdge_Order__c(
            Order_Status__c = 'New',
            Payment_Status__c = 'Pending'
        );
        insert order1;

        AgriEdge_OrderItem__c orderItem1 =
            new AgriEdge_OrderItem__c(
                Order__c = order1.Id,
                Quantity__c = 2,
                Unit_Price__c = 25
            );

        AgriEdge_OrderItem__c orderItem2 =
            new AgriEdge_OrderItem__c(
                Order__c = order1.Id,
                Quantity__c = 1,
                Unit_Price__c = 30
            );

        insert new List<AgriEdge_OrderItem__c>{
            orderItem1,
            orderItem2
        };

        AgriEdge_Order__c order2 = new AgriEdge_Order__c(
            Order_Status__c = 'New',
            Payment_Status__c = 'Pending'
        );
        insert order2;

        Set<Id> orderIds = new Set<Id>{
            order1.Id,
            order2.Id
        };

        Test.startTest();

        OrderTotalUpdater.updateOrderTotal(orderIds);

        Test.stopTest();

        Map<Id, AgriEdge_Order__c> updatedOrders =
            new Map<Id, AgriEdge_Order__c>(
                [
                    SELECT Id, Total_Amount__c, Payment_Status__c
                    FROM AgriEdge_Order__c
                    WHERE Id IN :orderIds
                ]
            );

        System.assertEquals(
            80,
            updatedOrders.get(order1.Id).Total_Amount__c,
            'Order total should be 80.'
        );

        System.assertEquals(
            'Pending',
            updatedOrders.get(order1.Id).Payment_Status__c,
            'Payment status should be Pending.'
        );

        System.assertEquals(
            0,
            updatedOrders.get(order2.Id).Total_Amount__c,
            'Order without items should have total 0.'
        );

        System.assertEquals(
            'Paid',
            updatedOrders.get(order2.Id).Payment_Status__c,
            'Zero total should result in Paid status.'
        );
    }


    // ---------------------------------------------------------
    // Test OrderEmailSender
    // ---------------------------------------------------------
    @isTest
public static void testSendOrderEmail() {

    Account testAccount = new Account(
        Name = 'Test Account'
    );
    insert testAccount;

    Contact contact1 = new Contact(
        FirstName = 'Test1',
        LastName = 'User1',
        Email = 'test1@example.com',
        AccountId = testAccount.Id
    );

    Contact contact2 = new Contact(
        FirstName = 'Test2',
        LastName = 'User2',
        Email = 'test2@example.com',
        AccountId = testAccount.Id
    );

    insert new List<Contact>{
        contact1,
        contact2
    };

    AgriEdge_Order__c order1 = new AgriEdge_Order__c(
        Order_Status__c = 'Processing',
        Payment_Status__c = 'Pending',
        Customer__c = testAccount.Id,
        Shipping_Address__c = '123 Test Street',
        Total_Amount__c = 100
    );

    insert order1;

    Set<Id> orderIds = new Set<Id>{
        order1.Id
    };

    Test.startTest();

    OrderEmailSender.sendOrderEmail(orderIds);

    Test.stopTest();

    // Verify that the customer contacts exist
    List<Contact> contacts = [
        SELECT Id, Email
        FROM Contact
        WHERE AccountId = :testAccount.Id
        AND Email != null
    ];

    System.assertEquals(
        2,
        contacts.size(),
        'Two customer contacts should exist.'
    );
}

    // ---------------------------------------------------------
    // Test AgriEdgeOrderShipmentHelper
    // ---------------------------------------------------------
    @isTest
    public static void testAgriEdgeOrderShipmentHelper() {

        AgriEdge_Order__c order = new AgriEdge_Order__c(
            Payment_Status__c = 'Pending',
            Order_Status__c = 'Processing'
        );
        insert order;

        Test.startTest();

        AgriEdgeOrderShipmentHelper.processOrderStatusChange(
            new List<AgriEdge_Order__c>{order}
        );

        Test.stopTest();

        List<AgriEdge_Shipment__c> shipments = [
            SELECT Id, Order__c, Status__c, Tracking_Number__c
            FROM AgriEdge_Shipment__c
            WHERE Order__c = :order.Id
        ];

        System.assertEquals(
            1,
            shipments.size(),
            'One shipment should be created.'
        );

        System.assertEquals(
            order.Id,
            shipments[0].Order__c,
            'Shipment should be linked to the correct order.'
        );

        System.assertEquals(
            'Pending',
            shipments[0].Status__c,
            'Shipment status should be Pending.'
        );
    }


    // ---------------------------------------------------------
    // Test AgriEdgeOrderTrigger
    // ---------------------------------------------------------
    @isTest
    public static void testAgriEdgeOrderTrigger() {

        AgriEdge_Order__c order = new AgriEdge_Order__c(
            Payment_Status__c = 'Pending',
            Order_Status__c = 'New'
        );

        insert order;

        Test.startTest();

        order.Payment_Status__c = 'Paid';
        update order;

        Test.stopTest();

        AgriEdge_Order__c updatedOrder = [
            SELECT Id, Order_Status__c
            FROM AgriEdge_Order__c
            WHERE Id = :order.Id
        ];

        System.assertEquals(
            'Delivered',
            updatedOrder.Order_Status__c,
            'Order status should become Delivered when payment is Paid.'
        );
    }


    // ---------------------------------------------------------
    // Test AgriEdgeOrderTriggerHelper
    // ---------------------------------------------------------
    @isTest
    public static void testAgriEdgeOrderTriggerHelper() {

        AgriEdgeOrderTriggerHelper.isTriggerExecuted = false;

        Boolean flagBeforeExecution =
            AgriEdgeOrderTriggerHelper.isTriggerExecuted;

        AgriEdgeOrderTriggerHelper.isTriggerExecuted = true;

        Boolean flagAfterExecution =
            AgriEdgeOrderTriggerHelper.isTriggerExecuted;

        System.assertEquals(
            false,
            flagBeforeExecution,
            'Flag should initially be false.'
        );

        System.assertEquals(
            true,
            flagAfterExecution,
            'Flag should become true.'
        );

        // Reset flag
        AgriEdgeOrderTriggerHelper.isTriggerExecuted = false;
    }
}