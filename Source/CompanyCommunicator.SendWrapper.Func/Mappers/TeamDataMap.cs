using System;
using CsvHelper.Configuration;
using Microsoft.Extensions.Localization;
using Microsoft.Teams.Apps.CompanyCommunicator.Common.Resources;
using Microsoft.Teams.Apps.CompanyCommunicator.SendWrapper.Func.Models;

namespace Microsoft.Teams.Apps.CompanyCommunicator.SendWrapper.Func.Mappers
{
    public sealed class TeamDataMap : ClassMap<TeamData>
    {
        private readonly IStringLocalizer<Strings> localizer;

        /// <summary>
        /// Initializes a new instance of the <see cref="TeamDataMap"/> class.
        /// </summary>
        /// <param name="localizer">Localization service.</param>
        public TeamDataMap(IStringLocalizer<Strings> localizer)
        {
            this.localizer = localizer ?? throw new ArgumentNullException(nameof(localizer));
            this.Map(x => x.Id).Name(this.localizer.GetString("ColumnName_TeamId"));
            this.Map(x => x.Name).Name(this.localizer.GetString("ColumnName_TeamName"));
            this.Map(x => x.DeliveryStatus).Name(this.localizer.GetString("ColumnName_DeliveryStatus"));
            this.Map(x => x.StatusReason).Name(this.localizer.GetString("ColumnName_StatusReason"));
            this.Map(x => x.Error).Name(this.localizer.GetString("ColumnName_Error"));
        }
    }
}
