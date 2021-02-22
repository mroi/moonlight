//
//  AlternateControllerNetworking.m
//  Moonlight for macOS
//
//  Created by Michael Kenny on 20/2/21.
//  Copyright © 2021 Moonlight Game Streaming Project. All rights reserved.
//

#import "AlternateControllerNetworking.h"
#import "Input.h"

#import "PlatformSockets.h"
#import "Connection.h"

extern struct sockaddr_storage RemoteAddr;
extern SOCKADDR_LEN RemoteAddrLen;


static SOCKET clientSocket = INVALID_SOCKET;
static SOCKET rumbleSocket = INVALID_SOCKET;

static dispatch_queue_t rumbleQueue;

typedef struct _NV_RUMBLE_PACKET {
    uint16_t playerIndex;
    uint16_t lowFreqMotor;
    uint16_t highFreqMotor;
} NV_RUMBLE_PACKET;

void CFDYSendMultiControllerEvent(short controllerNumber, short activeGamepadMask,
                                       short buttonFlags, unsigned char leftTrigger, unsigned char rightTrigger,
                                       short leftStickX, short leftStickY, short rightStickX, short rightStickY) {

    if (clientSocket == INVALID_SOCKET) {
        clientSocket = createSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP, true);
        if (clientSocket == SOCKET_ERROR) {
            NSLog(@"Error creating controller input socket: %d", LastSocketError());
        }
    }

    NV_MULTI_CONTROLLER_PACKET packet = {};
    
    packet.controllerNumber = controllerNumber;
    packet.activeGamepadMask = activeGamepadMask;
    packet.buttonFlags = buttonFlags;
    packet.leftTrigger = leftTrigger;
    packet.rightTrigger = rightTrigger;
    packet.leftStickX = leftStickX;
    packet.leftStickY = leftStickY;
    packet.rightStickX = rightStickX;
    packet.rightStickY = rightStickY;
    
    struct sockaddr_in *addr = malloc(RemoteAddrLen);
    memcpy(addr, &RemoteAddr, RemoteAddrLen);
    addr->sin_port = htons(48020);
    
    if (sendto(clientSocket, &packet, sizeof(packet), 0, (const struct sockaddr *)addr, RemoteAddrLen) < 0)
    {
        NSLog(@"Error sending controller packet: %d", LastSocketError());
    }
}

BOOL startListeningForRumblePackets(id<ConnectionCallbacks> connectionCallbacks) {
    rumbleSocket = createSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP, NO);
    
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(48020);
    
    if (bind(rumbleSocket, (struct sockaddr *)&addr, sizeof(addr)) == SOCKET_ERROR) {
        NSLog(@"Error binding port: %d", LastSocketError());
        return NO;
    }
    
    rumbleQueue = dispatch_queue_create("rumbleListenQueue", nil);
    dispatch_async(rumbleQueue, ^{
        while (YES) {
            char buffer[1000];
            ssize_t receiveLength = recvUdpSocket(rumbleSocket, buffer, sizeof(buffer), NO);
            if (receiveLength == SOCKET_ERROR) {
                if (LastSocketError() == EINTR || LastSocketError() == EBADF) {
                    break;
                }
                NSLog(@"Error receiving packet: %d", LastSocketError());
            } else {
                if (receiveLength >= sizeof(NV_RUMBLE_PACKET)) {
                    NV_RUMBLE_PACKET *rumblePacket = (NV_RUMBLE_PACKET *)buffer;
                    [connectionCallbacks rumble:rumblePacket->playerIndex lowFreqMotor:rumblePacket->lowFreqMotor highFreqMotor:rumblePacket->highFreqMotor];
                }
            }
        }
    });
    
    return YES;
}

void stopListeningForRumblePackets(void) {
    closeSocket(rumbleSocket);
}
