using Microsoft.Teams.Apps.CompanyCommunicator.SendWrapper.Func.Models;
using System;
using System.Collections.Generic;
using System.Text;

namespace Microsoft.Teams.Apps.CompanyCommunicator.SendWrapper.Func.Export
{
    public interface IDataStreamFacade
    {
        /// <summary>
        /// Get the user data list, which can be iterated asynchronously.
        /// </summary>
        /// <param name="notificationId">the notification id.</param>
        /// <param name="notificationStatus">the notification status.</param>
        /// <returns>the streams of user data.</returns>
        IAsyncEnumerable<IEnumerable<UserData>> GetUserDataStreamAsync(string notificationId, string notificationStatus);
    }
}
