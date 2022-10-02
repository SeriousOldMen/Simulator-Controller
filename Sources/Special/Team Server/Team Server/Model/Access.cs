﻿using SQLite;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace TeamServer.Model.Access {
    [Table("Access_Accounts")]
    public class Account : ModelObject {
        public enum ContractType : int { Expired = 0, OneTime = 1, FixedMinutes = 2, AdditionalMinutes = 3 };

        [Unique]
        public string Name { get; set; }

        public string EMail { get; set; }

        public string Password { get; set; }

        public bool Virgin { get; set; } = true;

        public bool Administrator { get; set; } = false;

        public int AvailableMinutes { get; set; }

        public ContractType Contract { get; set; } = ContractType.OneTime;

        public int ContractMinutes { get; set; } = 0;

        [Ignore]
        public List<SessionToken> SessionTokens
        {
            get {
                return ObjectManager.GetAccountSessionTokensAsync(this).Result;
            }
        }

        [Ignore]
        public DataToken DataToken
        {
            get {
                return ObjectManager.GetAccountDataTokenAsync(this).Result;
            }
        }

        [Ignore]
        public List<Team> Teams {
            get {
                return ObjectManager.GetAccountTeamsAsync(this).Result;
            }
        }

        [Ignore]
        public List<Session> Sessions
        {
            get {
                return ObjectManager.GetAccountSessionsAsync(this).Result;
            }
        }

        [Ignore]
        public List<Data.DataObject> Data
        {
            get {
                return ObjectManager.GetAccountDataAsync(this).Result;
            }
        }

        public override System.Threading.Tasks.Task Delete() {
            foreach (Team team in Teams)
                team.Delete();

            foreach (Session session in Sessions)
                session.Delete();

            ObjectManager.DoAccountTokensAsync(this, (Token token) => token.Delete());

            ObjectManager.DoAccountDataAsync(this, (Data.DataObject data) => data.Delete());

            return base.Delete();
        }
    }

    public abstract class Token : ModelObject
    {
        [Indexed]
        public int AccountID { get; set; }

        [Ignore]
        public Account Account
        {
            get {
                return ObjectManager.GetTokenAccountAsync(this).Result;
            }
        }

        [Ignore]
        public List<Connection> Connections
        {
            get {
                return ObjectManager.GetTokenConnectionsAsync(this).Result;
            }
        }

        public DateTime Created { get; set; }

        public DateTime Until { get; set; }

        public DateTime Used { get; set; } = DateTime.MinValue;

        public virtual bool IsValid()
        {
            return (Until == null) || (DateTime.Now < Until);
        }

        public virtual int GetRemainingMinutes()
        {
            return 0;
        }

        public override System.Threading.Tasks.Task Delete()
        {
            foreach (Connection connection in Connections)
                connection.Delete();

            return base.Delete();
        }
    }

    [Table("Access_Session_Tokens")]
    public class SessionToken : Token
    {
        public override bool IsValid() {
            if (base.IsValid())
                return true;
            else {
                if (Used != null)
                    return (DateTime.Now < Used + new TimeSpan(0, 5, 0));
                else
                    return false;
            }
        }

        public override int GetRemainingMinutes() {
            int usedMinutes = (int)(DateTime.Now - Created).TotalMinutes;

            return (7 * 24 * 60) - usedMinutes;
        }
    }

    [Table("Access_Data_Tokens")]
    public class DataToken : Token
    {
    }

    public class AdminToken : Token { }

    public enum ConnectionType
    {
        Unknown = 0,
        Internal = 1,
        Admin = 2,
        Driver = 3
    }

    [Table("Access_Connections")]
    public class Connection : ModelObject
    {
        [Indexed]
        public int TokenID { get; set; }


        [Indexed]
        public int SessionID { get; set; }

        [Ignore]
        public Token Token
        {
            get {
                return ObjectManager.GetTokenAsync(this.TokenID).Result;
            }
        }

        [Ignore]
        public Session Session
        {
            get {
                return ObjectManager.GetSessionAsync(this.SessionID).Result;
            }
        }

        public ConnectionType Type { get; set; }

        public string Client { get; set; }

        public string Name { get; set; }

        public DateTime Created { get; set; }

        public DateTime Until { get; set; } = DateTime.MinValue;

        public void Renew()
        {
            Until = DateTime.Now + TimeSpan.FromSeconds(Server.TeamServer.Instance.ConnectionLifeTime);

            Save();
        }

        public bool IsConnected()
        {
            return (DateTime.Now <= Until);
        }
    }
}