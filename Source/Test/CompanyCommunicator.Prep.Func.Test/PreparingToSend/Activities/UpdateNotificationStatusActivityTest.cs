﻿// <copyright file="UpdateNotificationStatusActivityTest.cs" company="Microsoft">
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
// </copyright>

namespace Microsoft.Teams.Apps.CompanyCommunicator.Prep.Func.Test.PreparingToSend.Activities
{
    using System;
    using System.Threading.Tasks;
    using FluentAssertions;
    using Microsoft.Teams.Apps.CompanyCommunicator.Common.Repositories.NotificationData;
    using Microsoft.Teams.Apps.CompanyCommunicator.Prep.Func.PreparingToSend;
    using Moq;
    using Xunit;

    /// <summary>
    /// UpdateNotificationStatusActivity test class.
    /// </summary>
    public class UpdateNotificationStatusActivityTest
    {
        private readonly Mock<INotificationDataRepository> notificationDataRepository = new Mock<INotificationDataRepository>();

        /// <summary>
        /// Constructor tests.
        /// </summary>
        [Fact]
        public void NotificationRepositoryConstructorTest()
        {
            // Arrange
            Action action1 = () => new UpdateNotificationStatusActivity(null /*notficationRepository*/);
            Action action2 = () => new UpdateNotificationStatusActivity(this.notificationDataRepository.Object);

            // Act and Assert.
            action1.Should().Throw<ArgumentNullException>("notifiationRepository is null.");
            action2.Should().NotThrow();
        }

        /// <summary>
        /// Test to check notification.
        /// </summary>
        /// <returns>A task that represents the work queued to execute.</returns>
        [Fact]
        public async Task UpdateNotificationStatusActivitySuccessTest()
        {
            // Arrange
            var activityContext = this.GetUpdateNotificationStatusActivity();
            var notificationId = "notificationId";
            this.notificationDataRepository
                .Setup(x => x.UpdateNotificationStatusAsync(It.IsAny<string>(), It.IsAny<NotificationStatus>()))
                .Returns(Task.CompletedTask);

            // Act
            Func<Task> task = async () => await activityContext.RunAsync((notificationId, NotificationStatus.Failed));

            // Assert
            await task.Should().NotThrowAsync();
            this.notificationDataRepository.Verify(x => x.UpdateNotificationStatusAsync(It.Is<string>(x => x.Equals(notificationId)), It.IsAny<NotificationStatus>()));
        }

        /// <summary>
        /// ArgumentNullException test.
        /// </summary>
        /// <returns>A task that represents the work queued to execute.</returns>
        [Fact]
        public async Task ArgumentNullExceptionTest()
        {
            // Arrange
            var activityContext = this.GetUpdateNotificationStatusActivity();

            // Act
            Func<Task> task = async () => await activityContext.RunAsync((null /*notificationId*/, NotificationStatus.Failed));

            // Assert
            await task.Should().ThrowAsync<ArgumentNullException>("notificationId is null");
        }

        /// <summary>
        /// Initializes a new mock instance of the <see cref="UpdateNotificationStatusActivity"/> class.
        /// </summary>
        private UpdateNotificationStatusActivity GetUpdateNotificationStatusActivity()
        {
            return new UpdateNotificationStatusActivity(this.notificationDataRepository.Object);
        }
    }
}
