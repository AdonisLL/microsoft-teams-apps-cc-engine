using Microsoft.Teams.Apps.CompanyCommunicator.SendWrapper.Func.Models;
using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;

namespace Microsoft.Teams.Apps.CompanyCommunicator.SendWrapper.Func.Services
{
    public  interface INotificationService
    {
        //Task<string> CreateDraftNotificationAsync(DraftNotification notification, string userName);
        Task<string> CreateSentNotification(DraftNotification draftNotification, string userName);
    }
}
