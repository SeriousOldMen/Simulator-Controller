﻿using System;
using System.Collections.Generic;
using TeamServer.Model;
using TeamServer.Model.Access;

namespace TeamServer.Server {
    public class TeamManager : ManagerBase {
        public TeamManager(ObjectManager objectManager, Model.Access.Token token) : base(objectManager, token) {
        }

        #region Team
        #region Query
        public List<Team> GetAllTeams() {
            return Token.Account.Teams;
        }

        public Team FindTeam(Guid identifier) {
            return ObjectManager.GetTeamAsync(identifier).Result;
        }

        public Team FindTeam(string identifier) {
            return FindTeam(new Guid(identifier));
        }

        public Team LookupTeam(Guid identifier) {
            Team team = FindTeam(identifier);

            ValidateTeam(team);

            return team;
        }

        public Team LookupTeam(string identifier) {
            return LookupTeam(new Guid(identifier));
        }
        #endregion

        #region CRUD
        public Team CreateTeam(Account account, string name) {
            Team team = new Team { AccountID = account.ID, Name = name };

            team.Save();

            return team;
        }

        public void DeleteTeam(Team team) {
            ValidateTeam(team);

            team.Delete();
        }

        public void DeleteTeam(Guid identifier) {
            DeleteTeam(ObjectManager.GetTeamAsync(identifier).Result);
        }

        public void DeleteTeam(string identifier) {
            DeleteTeam(new Guid(identifier));
        }
        #endregion
        #endregion

        #region Driver
        #region Query
        public Driver FindDriver(Guid identifier) {
            return ObjectManager.GetDriverAsync(identifier).Result;
        }

        internal Driver FindDriver(string identifier) {
            return FindDriver(new Guid(identifier));
        }

        public Driver LookupDriver(Guid identifier) {
            Driver driver = FindDriver(identifier);

            ValidateDriver(driver);

            return driver;
        }

        internal Driver LookupDriver(string identifier) {
            return LookupDriver(new Guid(identifier));
        }
        #endregion

        #region CRUD
        public Driver CreateDriver(Team team, string forName, string surName, string nickName) {
            Driver driver = new Driver { TeamID = team.ID, ForName = forName, SurName = surName, NickName = nickName };

            driver.Save();

            return driver;
        }

        public void DeleteDriver(Driver driver) {
            ValidateDriver(driver);

            driver.Delete();
        }

        public void DeleteDriver(Guid identifier) {
            DeleteDriver(ObjectManager.GetDriverAsync(identifier).Result);
        }

        public void DeleteDriver(string identifier) {
            DeleteDriver(new Guid(identifier));
        }
        #endregion
        #endregion
    }
}
