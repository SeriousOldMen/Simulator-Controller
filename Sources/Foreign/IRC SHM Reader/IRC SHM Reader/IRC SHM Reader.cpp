/*
Based on sample code by iRacing Motorsport Simulations, LLC.

The following apply:

Copyright (c) 2013, iRacing.com Motorsport Simulations, LLC.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of iRacing.com Motorsport Simulations nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

//------
#define MIN_WIN_VER 0x0501

#ifndef WINVER
#	define WINVER			MIN_WIN_VER
#endif

#ifndef _WIN32_WINNT
#	define _WIN32_WINNT		MIN_WIN_VER 
#endif

#pragma warning(disable:4996) //_CRT_SECURE_NO_WARNINGS

#include <windows.h>
#include <stdio.h>
#include <conio.h>
#include <signal.h>
#include <time.h>

#include "irsdk_defines.h"
#include "yaml_parser.h"

// for timeBeginPeriod
#pragma comment(lib, "Winmm")

// 32 ms timeout
#define TIMEOUT 32

char *g_data = NULL;

const char g_playerInCarString[] = "IsOnTrack";
int g_playerInCarOffset = -1;

const char g_sessionTimeString[] = "SessionTime";
int g_sessionTimeOffset = -1;

const char g_lapIndexString[] = "Lap";
int g_lapIndexOffset = -1;


// place holders for variables that need to be updated in the header of our CSV file
double startTime;
long int startTimeOffset;

double endTime;
long int endTimeOffset;

int lastLap;
int lapCount;
long int lapCountOffset;

inline double normalize(double value) {
	return (value < 0) ? 0.0 : value;
}

inline double GetPsi(double kPa) {
	return kPa / 6.895;
}

inline double GetKpa(double psi) {
	return psi * 6.895;
}

void substring(const char s[], char sub[], int p, int l) {
	int c = 0;

	while (c < l) {
		sub[c] = s[p + c];

		c++;
	}
	sub[c] = '\0';
}

inline void extractString(char* string, const char* value, int valueLength) {
	substring(value, string, 0, valueLength);
}

bool getYamlValue(char* result, const char* sessionInfo, char* path) {
	int length = -1;
	const char* string;

	if (parseYaml(sessionInfo, path, &string, &length)) {
		extractString(result, string, length);

		return true;
	}
	else
		return false;
}

bool getYamlValue(char* result, const char* sessionInfo, char* path, char* value) {
	char buffer[256];
	int pos = 0;

	sprintf(buffer, path, value);

	return getYamlValue(result, sessionInfo, buffer);
}

bool getYamlValue(char* result, const char* sessionInfo, char* path, char* value1, char* value2) {
	char buffer[256];
	int pos = 0;

	sprintf(buffer, path, value1, value2);

	return getYamlValue(result, sessionInfo, buffer);
}

int getCurrentSessionID(const char* sessionInfo) {
	char id[10];
	char result[100];
	int sID = 0;

	while (getYamlValue(result, sessionInfo, "SessionInfo:Sessions:SessionNum:{%s}ResultsOfficial:", itoa(sID, id, 10))) {
		if (strcmp(result, "0") == 0)
			return sID;

		sID += 1;
	}

	return -1;
}

long getRemainingTime(const char* sessionInfo, int sessionLaps, long sessionTime, int lap, long lastTime);

long getRemainingLaps(const char* sessionInfo, int sessionLaps, long sessionTime, int lap, long lastTime) {
	char result[100];

	if (lap < 1)
		return 0;

	if (sessionLaps > 0)
		return (long)(sessionLaps - lap);
	else if (lastTime > 0)
		return (long)(getRemainingTime(sessionInfo, sessionLaps, sessionTime, lap, lastTime) / lastTime);
	else
		return 0;
}

long getRemainingTime(const char* sessionInfo, int sessionLaps, long sessionTime, int lap, long lastTime) {
	if (lap < 1)
		return 0;

	if (sessionLaps == -1)
		return (sessionTime - (lastTime * lap));
	else
		return (getRemainingLaps(sessionInfo, sessionLaps, sessionTime, lap, lastTime) * lastTime);
}

void printDataValue(const irsdk_header* header, const char* data, const irsdk_varHeader* rec) {
	if (header && data) {
		int count = rec->count;

		for (int j = 0; j < count; j++)
		{
			switch (rec->type)
			{
			case irsdk_char:
				printf("%s", (char*)(data + rec->offset)); break;
			case irsdk_bool:
				printf("%d", ((bool*)(data + rec->offset))[j]); break;
			case irsdk_int:
				printf("%d", ((int*)(data + rec->offset))[j]); break;
			case irsdk_bitField:
				printf("0x%08x", ((int*)(data + rec->offset))[j]); break;
			case irsdk_float:
				printf("%0.2f", ((float*)(data + rec->offset))[j]); break;
			case irsdk_double:
				printf("%0.2f", ((double*)(data + rec->offset))[j]); break;
			}

			if (j + 1 < count)
				printf(", ");
		}
	}
}

void printDataValue(const irsdk_header* header, const char* data, const char* variable) {
	if (header && data) {
		for (int i = 0; i < header->numVars; i++) {
			const irsdk_varHeader* rec = irsdk_getVarHeaderEntry(i);

			if (strcmp(rec->name, variable) == 0) {
				printDataValue(header, data, rec);

				break;
			}
		}
	}
}

bool getDataValue(char* value, const irsdk_header* header, const char* data, const char* variable) {
	if (header && data) {
		for (int i = 0; i < header->numVars; i++) {
			const irsdk_varHeader* rec = irsdk_getVarHeaderEntry(i);

			if (strcmp(rec->name, variable) == 0) {
				switch (rec->type)
				{
				case irsdk_char:
					sprintf(value, "%s", (char*)(data + rec->offset)); break;
				case irsdk_bool:
					sprintf(value, "%d", ((bool*)(data + rec->offset))[0]); break;
				case irsdk_bitField:
				case irsdk_int:
					sprintf(value, "%d", ((int*)(data + rec->offset))[0]); break;
				case irsdk_float:
					sprintf(value, "%0.2f", ((float*)(data + rec->offset))[0]); break;
				case irsdk_double:
					sprintf(value, "%0.2f", ((double*)(data + rec->offset))[0]); break;
				default:
					return false;
				}

				return true;
			}
		}
	}

	return false;
}

float getDataFloat(const irsdk_header* header, const char* data, const char* variable) {
	char result[32];
	float value = 0;

	if (getDataValue(result, header, data, variable))
		sscanf(result, "%f", &value);

	return value;
}

void setPitstopRefuelAmount(char* values) {
	float fuelAmount;

	sscanf(values, "%f", &fuelAmount);

	if (fuelAmount == 0)
		irsdk_broadcastMsg(irsdk_BroadcastPitCommand, irsdk_PitCommand_ClearFuel, 0);
	else
		irsdk_broadcastMsg(irsdk_BroadcastPitCommand, irsdk_PitCommand_Fuel, fuelAmount);
}

void requestPitstopRepairs(char* values) {
	if (strcmp(values, "true") == 0)
		irsdk_broadcastMsg(irsdk_BroadcastPitCommand, irsdk_PitCommand_FR, 0);
	else
		irsdk_broadcastMsg(irsdk_BroadcastPitCommand, irsdk_PitCommand_ClearFR, 0);
}

void requestPitstopTyreChange(char* values) {
	if (strcmp(values, "true") == 0) {
		irsdk_broadcastMsg(irsdk_BroadcastPitCommand, irsdk_PitCommand_LF, 0);
		irsdk_broadcastMsg(irsdk_BroadcastPitCommand, irsdk_PitCommand_RF, 0);
		irsdk_broadcastMsg(irsdk_BroadcastPitCommand, irsdk_PitCommand_LR, 0);
		irsdk_broadcastMsg(irsdk_BroadcastPitCommand, irsdk_PitCommand_RR, 0);
	}
	else
		irsdk_broadcastMsg(irsdk_BroadcastPitCommand, irsdk_PitCommand_ClearTires, 0);
}

void setTyrePressure(int command, float pressure) {
	irsdk_broadcastMsg(irsdk_BroadcastPitCommand, command, (int)GetKpa(pressure));
}

void setPitstopTyrePressures(char* values) {
	char buffer[32];

	float pressure;
	float pressures[3];

	for (int i = 0; i < 3; i++) {
		size_t length = strcspn(values, ";");
		
		substring(values, buffer, 0, length);

		sscanf(buffer, "%f", &pressure);

		pressures[i] = pressure;

		values += (length + 1);
	}

	sscanf(values, "%f", &pressure);

	setTyrePressure(irsdk_PitCommand_LF, pressures[0]);
	setTyrePressure(irsdk_PitCommand_RF, pressures[1]);
	setTyrePressure(irsdk_PitCommand_LR, pressures[2]);
	setTyrePressure(irsdk_PitCommand_RR, pressure);
}

void pitstopSetValues(const irsdk_header* header, const char* data, char* arguments) {
	char service[64];
	char values[64];
	size_t length = strcspn(arguments, ":");

	substring((char*)arguments, service, 0, length);
	substring((char*)arguments, values, length + 1, strlen(arguments) - length - 1);

	if (strcmp(service, "Refuel") == 0)
		setPitstopRefuelAmount(values);
	else if (strcmp(service, "Repair") == 0)
		requestPitstopRepairs(values);
	else if (strcmp(service, "Tyre Change") == 0)
		requestPitstopTyreChange(values);
	else if (strcmp(service, "Tyre Pressure") == 0)
		setPitstopTyrePressures(values);
}

void changePitstopRefuelAmount(const irsdk_header* header, const char* data, char* values) {
	float fuelDelta;

	sscanf(values, "%f", &fuelDelta);

	if (fuelDelta != 0)
		irsdk_broadcastMsg(irsdk_BroadcastPitCommand, irsdk_PitCommand_Fuel, getDataFloat(header, data, "PitSvFuel") + fuelDelta);
}

void changePitstopTyrePressure(const irsdk_header* header, const char* data, char* tyre, char* values) {
	float pressureDelta;

	sscanf(values, "%f", &pressureDelta);

	if (strcmp(tyre, "FL") == 0)
		setTyrePressure(irsdk_PitCommand_LF, GetPsi(getDataFloat(header, data, "PitSvLFP")) + pressureDelta);
	else if (strcmp(tyre, "FR") == 0)
		setTyrePressure(irsdk_PitCommand_RF, GetPsi(getDataFloat(header, data, "PitSvRFP")) + pressureDelta);
	else if (strcmp(tyre, "RL") == 0)
		setTyrePressure(irsdk_PitCommand_LR, GetPsi(getDataFloat(header, data, "PitSvLRP")) + pressureDelta);
	else if (strcmp(tyre, "RR") == 0)
		setTyrePressure(irsdk_PitCommand_RR, GetPsi(getDataFloat(header, data, "PitSvRRP")) + pressureDelta);
}

void pitstopChangeValues(const irsdk_header* header, const char* data, char* arguments) {
	char service[64];
	char values[64];
	size_t length = strcspn(arguments, ":");

	substring((char*)arguments, service, 0, length);
	substring((char*)arguments, values, length + 1, strlen(arguments) - length - 1);

	if (strcmp(service, "Refuel") == 0)
		changePitstopRefuelAmount(header, data, values);
	else if (strcmp(service, "Repair") == 0)
		requestPitstopRepairs(values);
	else if (strcmp(service, "Tyre Change") == 0)
		requestPitstopTyreChange(values);
	else if (strcmp(service, "All Around") == 0) {
		changePitstopTyrePressure(header, data, "FL", values);
		changePitstopTyrePressure(header, data, "FR", values);
		changePitstopTyrePressure(header, data, "RL", values);
		changePitstopTyrePressure(header, data, "RR", values);
	}
	else if (strcmp(service, "Front Left") == 0)
		changePitstopTyrePressure(header, data, "FL", values);
	else if (strcmp(service, "Front Right") == 0)
		changePitstopTyrePressure(header, data, "FR", values);
	else if (strcmp(service, "Rear Left") == 0)
		changePitstopTyrePressure(header, data, "RL", values);
	else if (strcmp(service, "Rear Right") == 0)
		changePitstopTyrePressure(header, data, "RR", values);
}

void writeData(const irsdk_header *header, const char* data, bool setupOnly)
{
	if(header && data)
	{
		const char* sessionInfo = irsdk_getSessionInfoStr();
		char playerCarIdx[10] = "";
		char sessionID[10] = "";

		getYamlValue(playerCarIdx, sessionInfo, "DriverInfo:DriverCarIdx:");

		itoa(getCurrentSessionID(sessionInfo), sessionID, 10);

		char result[100];

		int sessionLaps = -1;
		long sessionTime = -1;
		int laps = 0;
		float maxFuel = 0;

		if (getYamlValue(result, sessionInfo, "SessionInfo:Sessions:SessionNum:{%s}ResultsPositions:CarIdx:{%s}LapsComplete:", sessionID, playerCarIdx))
			laps = atoi(result);

		if (getYamlValue(result, sessionInfo, "SessionInfo:Sessions:SessionNum:{%s}SessionLaps:", sessionID))
			if (strcmp(result, "unlimited") != 0)
				sessionLaps = atoi(result);
			else if (getYamlValue(result, sessionInfo, "SessionInfo:Sessions:SessionNum:{%s}SessionTime:", sessionID)) {
				char buffer[64];
				float time;

				size_t length = strcspn(result, " ");

				substring((char*)result, buffer, 0, length);

				sscanf(buffer, "%f", &time);

				sessionTime = ((long)time * 1000);
			}
			else {
				sessionTime = 0;
			}

		if (getYamlValue(result, sessionInfo, "DriverInfo:DriverCarFuelMaxLtr:"))
			sscanf(result, "%f", &maxFuel);

		long lastTime = 0;
		long bestTime = 0;

		float fLastTime = 0;
		float fBestTime = 0;

		if (getYamlValue(result, sessionInfo, "SessionInfo:Sessions:SessionNum:{%s}ResultsPositions:CarIdx:{%s}LastTime:", sessionID, playerCarIdx))
			sscanf(result, "%f", &fLastTime);

		if (getYamlValue(result, sessionInfo, "SessionInfo:Sessions:SessionNum:{%s}ResultsPositions:CarIdx:{%s}FastestTime:", sessionID, playerCarIdx))
			sscanf(result, "%f", &fBestTime);

		lastTime = (long)(normalize(fLastTime) * 1000);
		bestTime = (long)(normalize(fBestTime) * 1000);

		if (bestTime == 0)
			bestTime = lastTime;

		if (setupOnly) {
			printf("[Setup Data]\n");

			printf("TyreCompound=Dry\n");
			printf("TyreCompoundColor=Black\n");
			printf("TyreSet=1\n");

			printf("TyrePressure = %f, %f, %f, %f\n",
				GetPsi(getDataFloat(header, data, "LFcoldPressure")),
				GetPsi(getDataFloat(header, data, "RFcoldPressure")),
				GetPsi(getDataFloat(header, data, "LRcoldPressure")),
				GetPsi(getDataFloat(header, data, "RRcoldPressure")));
		}
		else {
			printf("[Session Data]\n");

			printf("Active=true\n");
			printf("Paused=false\n"); // Not yet implemented

			if (getYamlValue(result, sessionInfo, "SessionInfo:Sessions:SessionNum:{%s}SessionType:", sessionID)) {
				if (strstr(result, "Practice"))
					printf("Session=Practice\n");
				else if (strstr(result, "Qualify"))
					printf("Session=Qualification\n");
				else if (strstr(result, "Race"))
					printf("Session=Race\n");
				else
					printf("Session=Other\n");
			}
			else
				printf("Session=Other\n");

			printf("FuelAmount=%f\n", maxFuel);

			if (getYamlValue(result, sessionInfo, "WeekendInfo:TrackName:"))
				printf("Track=%s\n", result);
			else
				printf("Track=Unknown\n");

			if (getYamlValue(result, sessionInfo, "DriverInfo:Drivers:CarIdx:{%s}CarScreenName:", playerCarIdx))
				printf("Car=%s\n", result);
			else
				printf("Car=Unknown\n");

			printf("SessionFormat=%s\n", (sessionLaps == -1) ? "Time" : "Lap");

			printf("[Car Data]\n");

			printf("BodyworkDamage=0,0,0,0,0\n");
			printf("SuspensionDamage=0,0,0,0\n");

			printf("FuelRemaining=%f\n", getDataFloat(header, data, "FuelLevel"));

			printf("TyreCompound=Dry\n");
			printf("TyreCompoundColor=Black\n");

			printf("TyrePressure = %f, %f, %f, %f\n",
				GetPsi(getDataFloat(header, data, "LFpressure")),
				GetPsi(getDataFloat(header, data, "RFpressure")),
				GetPsi(getDataFloat(header, data, "LRpressure")),
				GetPsi(getDataFloat(header, data, "RRpressure")));

			printf("TyreTemperature = %f, %f, %f, %f\n",
				(getDataFloat(header, data, "LFtempL") + getDataFloat(header, data, "LFtempM") + getDataFloat(header, data, "LFtempR")) / 3,
				(getDataFloat(header, data, "RFtempL") + getDataFloat(header, data, "RFtempM") + getDataFloat(header, data, "RFtempR")) / 3,
				(getDataFloat(header, data, "LRtempL") + getDataFloat(header, data, "LRtempM") + getDataFloat(header, data, "LRtempR")) / 3,
				(getDataFloat(header, data, "RRtempL") + getDataFloat(header, data, "RRtempM") + getDataFloat(header, data, "RRtempR")) / 3);

			printf("[Stint Data]\n");

			if (getYamlValue(result, sessionInfo, "DriverInfo:Drivers:CarIdx:{%s}UserName:", playerCarIdx)) {
				char forName[100];
				char surName[100];
				char nickName[3];

				size_t length = strcspn(result, " ");

				substring((char*)result, forName, 0, length);
				substring((char*)result, surName, length + 1, strlen(result) - length - 1);
				nickName[0] = forName[0], nickName[1] = surName[0], nickName[2] = '\0';

				printf("DriverForname=%s\n", forName);
				printf("DriverSurname=%s\n", surName);
				printf("DriverNickname=%s\n", nickName);
			}
			else {
				printf("DriverForname=John\n");
				printf("DriverSurname=Doe\n");
				printf("DriverNickname=JD\n");
			}

			printf("Laps=%s\n", itoa(laps, result, 10));

			printf("LapLastTime=%ld\n", lastTime);
			printf("LapBestTime=%ld\n", bestTime);

			long lapsRemaining = -1;
			long timeRemaining = -1;

			if (getDataValue(result, header, data, "SessionLapsRemain"))
				lapsRemaining = atoi(result);

			if (lapsRemaining == -1)
				lapsRemaining = getRemainingLaps(sessionInfo, sessionLaps, sessionTime, laps, lastTime);

			printf("SessionLapsRemaining=%ld\n", lapsRemaining);

			if (getDataValue(result, header, data, "SessionTimeRemain")) {
				float time;

				sscanf(result, "%f", &time);

				if (time != -1)
					timeRemaining = ((long)time * 1000);
			}

			if (timeRemaining == -1)
				timeRemaining = getRemainingTime(sessionInfo, sessionLaps, sessionTime, laps, lastTime);

			printf("SessionTimeRemaining=%ld\n", timeRemaining);
			printf("StintTimeRemaining=%ld\n", timeRemaining);
			printf("DriverTimeRemaining=%ld\n", timeRemaining);

			if (getDataValue(result, header, data, "PitSvFlags"))
				printf("InPit=%s\n", atoi(result) ? "true" : "false");
			else
				printf("InPit=false\n");

			printf("[Track Data]\n");

			if (getYamlValue(result, sessionInfo, "WeekendInfo:TrackSurfaceTemp:")) {
				char temperature[10];
				size_t length = strcspn(result, " ");

				substring((char*)result, temperature, 0, length);

				printf("Temperature=%s\n", temperature);
			}
			else
				printf("Temperature=24\n");

			char gripLevel[32] = "Green";

			int id = atoi(sessionID);

			while (id) {
				char session[32];

				if (getYamlValue(result, sessionInfo, "SessionInfo:Sessions:SessionNum:{%s}SessionTrackRubberState:", itoa(id, session, 10)))
					if (strstr(result, "high") && strstr(result, "moderately"))
						strcpy(gripLevel, "Fast");
					else if (strstr(result, "high"))
						strcpy(gripLevel, "Optimum");
					else if (!strstr(result, "carry over"))
						break;

				id -= 1;
			}

			printf("Grip=%s\n", gripLevel);

			printf("[Weather Data]\n");

			if (getYamlValue(result, sessionInfo, "WeekendInfo:TrackAirTemp:")) {
				char temperature[10];
				size_t length = strcspn(result, " ");

				substring((char*)result, temperature, 0, length);

				printf("Temperature=%s\n", temperature);
			}
			else
				printf("Temperature=24\n");

			printf("Weather=Dry\n");
			printf("Weather10Min=Dry\n");
			printf("Weather30Min=Dry\n");
		}

		// printf("[Debug]\n");
		// printf("%s", sessionInfo);
	}
}

int main(int argc, char* argv[])
{
	// bump priority up so we get time from the sim
	SetPriorityClass(GetCurrentProcess(), HIGH_PRIORITY_CLASS);

	// ask for 1ms timer so sleeps are more precise
	timeBeginPeriod(1);

	g_data = NULL;
	int tries = 3;

	while (tries-- > 0) {
		// wait for new data and copy it into the g_data buffer, if g_data is not null
		if (irsdk_waitForDataReady(TIMEOUT, g_data)) {
			const irsdk_header* pHeader = irsdk_getHeader();

			if (pHeader)
			{
				if ((argc > 2) && (strcmp(argv[1], "-Pitstop") == 0)) {
					if (strcmp(argv[2], "Set") == 0)
						pitstopSetValues(pHeader, g_data, argv[3]);
					else if (strcmp(argv[2], "Change") == 0)
						pitstopChangeValues(pHeader, g_data, argv[3]);
				}
				else
					writeData(pHeader, g_data, ((argc == 2) && (strcmp(argv[1], "-Setup") == 0)));

				break;
			}
		}
	}

	if (tries == 0) {
		printf("[Session Data]\n");
		printf("Active=false\n");
	}
	
	irsdk_shutdown();
	timeEndPeriod(1);

	return 0;
}

