﻿using SQLite;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace TeamServer.Model.Store
{
    public abstract class StoreObject : ModelObject
    {
        [Indexed]
        public int AccountID { get; set; }

        [Ignore]
        public TeamServer.Model.Access.Account Account
        {
            get {
                return ObjectManager.GetAccountAsync(this.AccountID).Result;
            }
        }
    }

    [Table("Store_Licenses")]
    public class License : StoreObject
    {
        [Indexed]
        public string LID { get; set; }

        public string Forname { get; set; }

        public string Surname { get; set; }

        public string Nickname { get; set; }
    }

    public abstract class SimulatorObject : StoreObject
    {
        public string Simulator { get; set; }

        [Indexed]
        public string Car { get; set; }

        [Indexed]
        public string Track { get; set; }

        [Indexed]
        public string Driver { get; set; }
    }

    public abstract class TelemetryObject : SimulatorObject
    {
        public string Weather { get; set; }

        public float AirTemperature { get; set; }

        public float TrackTemperature { get; set; }

        public string TyreCompound { get; set; }

        public string TyreCompoundColor { get; set; }

        public float FuelRemaining { get; set; }

        public float FuelConsumption { get; set; }

        public float LapTime { get; set; }
    }

    [Table("Store_Electronics")]
    public class Electronics : TelemetryObject
    {
        public string Map { get; set; }

        public string TC { get; set; }

        public string ABS { get; set; }
    }

    [Table("Store_Tyres")]
    public class Tyres : TelemetryObject
    {
        public int Laps { get; set; }

        public float PressureFrontLeft { get; set; }

        public float PressureFrontRight { get; set; }

        public float PressureRearLeft { get; set; }

        public float PressureRearRight { get; set; }

        public float TemperatureFrontLeft { get; set; }

        public float TemperatureFrontRight { get; set; }

        public float TemperatureRearLeft { get; set; }

        public float TemperatureRearRight { get; set; }

        public float WearFrontLeft { get; set; }

        public float WearFrontRight { get; set; }

        public float WearRearLeft { get; set; }

        public float WearRearRight { get; set; }
    }

    [Table("Store_Brakes")]
    public class Brakes : TelemetryObject
    {
        public int Laps { get; set; }

        public float RotorWearFrontLeft { get; set; }

        public float RotorWearFrontRight { get; set; }

        public float RotorWearRearLeft { get; set; }

        public float RotorWearRearRight { get; set; }

        public float PadWearFrontLeft { get; set; }

        public float PadWearFrontRight { get; set; }

        public float PadWearRearLeft { get; set; }

        public float PadWearRearRight { get; set; }
    }

    public abstract class PressuresObject : SimulatorObject
    {
        [Indexed]
        public string Weather { get; set; }

        [Indexed]
        public float AirTemperature { get; set; }

        [Indexed]
        public float TrackTemperature { get; set; }

        public string TyreCompound { get; set; }

        public string TyreCompoundColor { get; set; }
    }

    [Table("Store_Tyres_Pressures")]
    public class TyresPressures : PressuresObject
    {
        public float HotPressureFrontLeft { get; set; }

        public float HotPressureFrontRight { get; set; }

        public float HotPressureRearLeft { get; set; }

        public float HotPressureRearRight { get; set; }

        public float ColdPressureFrontLeft { get; set; }

        public float ColdPressureFrontRight { get; set; }

        public float ColdPressureRearLeft { get; set; }

        public float ColdPressureRearRight { get; set; }
    }

    [Table("Store_Tyres_Pressures_Distribution")]
    public class TyresPressuresDistribution : PressuresObject
    {
        public string Type { get; set; }

        public string Tyre { get; set; }

        public float Pressure { get; set; }

        public int Count { get; set; }
    }
}