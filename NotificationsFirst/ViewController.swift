//
//  ViewController.swift
//  NotificationsFirst
//
//  Created by Nikolas Omelianov on 07.07.2018.
//  Copyright © 2018 Nikolas Omelianov. All rights reserved.
//

import UIKit
import UserNotifications

class ViewController: UIViewController, UNUserNotificationCenterDelegate {
    var pizzaNumber = 0
    let pizzaSteps = ["Make Pizza","Roll Dough","Add Sause","Add Cheese","Add Ingrefients","Bake ","Done"]
    func updatePizzaStep(request: UNNotificationRequest){
        if request.identifier.hasPrefix("message.pizza") {
            var stepNumber = request.content.userInfo["step"] as! Int
            stepNumber = (stepNumber + 1) % pizzaSteps.count
            let updatedContent = makePizzaContent()
            updatedContent.body = pizzaSteps[stepNumber]
            updatedContent.userInfo["step"] = stepNumber
            updatedContent.subtitle = request.content.subtitle
            addNotification(trigger: request.trigger, content: updatedContent, identifier: request.identifier)
        }
    }
    var isGrantedNotificationAccess = false
    func makePizzaContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "A Timed Piza Step"
        content.body = "Making Pizza"
        content.userInfo = ["step": 0]
        content.categoryIdentifier = "pizza.steps.category"
        return content
    }
    func addNotification(trigger : UNNotificationTrigger?, content: UNMutableNotificationContent, identifier: String) {
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) {
            (error) in
            if error != nil {
                print("error adding notification:\(error?.localizedDescription ?? "whoops")")
            }
        }
    }
    
    @IBAction func Scedule(_ sender: UIButton) {
        if isGrantedNotificationAccess{
            let content = UNMutableNotificationContent()
            content.title = "A sceduled pizza"
            content.body = "time to make a Pizza"
            content.categoryIdentifier = "snooze.category"
            let unitFlags: Set<Calendar.Component> = [.minute,.hour,.second]
            var date = Calendar.current.dateComponents(unitFlags, from: Date())
            date.second = date.second! + 15
            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
            addNotification(trigger: trigger, content: content, identifier: "message.scedule")
            
        }
    }
    
    @IBAction func Make(_ sender: UIButton) {
        if isGrantedNotificationAccess{
            let content = makePizzaContent()
            pizzaNumber += 1
            content.subtitle = "Pizza \(pizzaNumber)"
            
            let trigget = UNTimeIntervalNotificationTrigger(timeInterval: 7.0, repeats: false)
//            let trigget = UNTimeIntervalNotificationTrigger(timeInterval: 60.0, repeats: true)
            addNotification(trigger: trigget, content: content, identifier: "message.pizza.\(pizzaNumber)")
        }
    }
    
    @IBAction func Next(_ sender: UIButton) {
        UNUserNotificationCenter.current().getPendingNotificationRequests
            { (requests) in
                if let request = requests.first {
                    if request.identifier.hasPrefix("message.pizza"){
                        self.updatePizzaStep(request: request)
                    } else {
                        let content = request.content.mutableCopy() as! UNMutableNotificationContent
                        self.addNotification(trigger: request.trigger, content: content, identifier: request.identifier)
                    }
                }
            }
    }
    
    @IBAction func Pending(_ sender: UIButton) {
        UNUserNotificationCenter.current().getPendingNotificationRequests{(requestList) in
                print("\(Date()) --> \(requestList.count) request pending")
            for request in requestList {
                print("\(request.identifier) body:\(request.content.body)")
            }
        }
    }
    
    @IBAction func Delivered(_ sender: UIButton) {
        UNUserNotificationCenter.current().getDeliveredNotifications { (notifications) in
            print ("\(Date()) ---\(notifications.count) delivered")
            for notification in notifications {
                print("\(notification.request.identifier)    \(notification.request.content.body)")
            }
        }
    }
    
    @IBAction func Remove(_ sender: UIButton) {
        UNUserNotificationCenter.current().getPendingNotificationRequests {
            (requests) in
            if let reqest = requests.first {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reqest.identifier])
            }
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.badge,.sound,]) { (granted, error) in
            self.isGrantedNotificationAccess = granted
            if !granted {
                //TODO
            }
        }
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert,.sound])
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let action = response.actionIdentifier
        let request = response.notification.request
        if action == "next.step.action" {
            updatePizzaStep(request: request)
        }
        if action == "stop.action" {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [request.identifier])
        }
        if action == "snooze.action" {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5.0, repeats: false)
            let newRequest = UNNotificationRequest(identifier: request.identifier, content: request.content, trigger: trigger)
            UNUserNotificationCenter.current().add(newRequest) { (error) in
                if error != nil {
                    print("\(error?.localizedDescription ?? "error snooze")")
                }
            }
        }
        if action == "text.input" {
            let textResponse = response as! UNTextInputNotificationResponse
            let newContent = request.content.mutableCopy() as! UNMutableNotificationContent
            newContent.subtitle = textResponse.userText
            addNotification(trigger: request.trigger, content: newContent, identifier: request.identifier)
        }
        completionHandler()
    }


}

