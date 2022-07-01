﻿// <copyright file="IExportQueue.cs" company="Microsoft">
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
// </copyright>

namespace Microsoft.Teams.Apps.CompanyCommunicator.Common.Services.MessageQueues.ExportQueue
{
    /// <summary>
    /// interface for Export Queue.
    /// </summary>
    public interface IExportQueue : IBaseQueue<ExportQueueMessageContent>
    {
    }
}
