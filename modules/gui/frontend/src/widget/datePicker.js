import guid from 'guid'
import _ from 'lodash'
import moment from 'moment'
import * as PropTypes from 'prop-types'
import React, {Component} from 'react'
import {activatable} from 'widget/activation/activatable'
import {Activator} from 'widget/activation/activator'
import {Button} from 'widget/button'
import styles from './datePicker.module.css'
import {Input} from './form'
import Label from './label'
import {Panel, PanelButtons, PanelContent, PanelHeader} from './panel'
import {Scrollable, ScrollableContainer} from './scrollable'

const DATE_FORMAT = 'YYYY-MM-DD'

export default class DatePicker extends React.Component {
    id = 'DatePicker-' + guid()

    render() {
        const {input, startDate, endDate, label, autoFocus} = this.props
        return (
            <Activator id={this.id}>
                {panel =>
                    <div className={styles.container}>
                        <DatePickerPanel
                            id={this.id}
                            title={label}
                            date={moment(input.value, DATE_FORMAT)}
                            startDate={_.isString(startDate) ? moment(startDate, DATE_FORMAT) : moment(startDate)}
                            endDate={_.isString(endDate) ? moment(endDate, DATE_FORMAT) : moment(endDate)}
                            onSelect={date => input.set(date.format(DATE_FORMAT))}/>
                        {this.renderLabel()}
                        <div className={styles.input}>
                            <Input
                                autoFocus={autoFocus}
                                input={input}
                                maxLength={10}
                                autoComplete='off'
                                className={styles.input}
                            />
                            <Button additionalClassName={styles.panelTrigger}
                                    chromeless
                                    icon='calendar-alt'
                                    size='small'
                                    onClick={() => panel.activate()}
                            />
                        </div>
                    </div>
                }
            </Activator>
        )
    }

    renderLabel() {
        const {label, tooltip, tooltipPlacement = 'top'} = this.props
        return label ? (
            <Label
                msg={label}
                tooltip={tooltip}
                tooltipPlacement={tooltipPlacement}
            />
        ) : null
    }

    componentDidMount() {
        this.setToValidRange()
    }

    componentDidUpdate(prevProps, prevState, snapshot) {
        if (prevProps.input.value !== this.props.input.value)
            this.setToValidRange()
    }

    setToValidRange() {
        const {input, startDate, endDate} = this.props
        const date = moment(input.value, DATE_FORMAT)
        const validDate = moment.max(moment.min(moment(date), moment(endDate)), moment(startDate))
        if (!date.isSame(validDate))
            input.set(validDate.format(DATE_FORMAT))
    }
}

DatePicker.propTypes = {
    input: PropTypes.object.isRequired,
    startDate: PropTypes.any.isRequired,
    endDate: PropTypes.any.isRequired,
    label: PropTypes.string,
    autoFocus: PropTypes.any
}


class _DatePickerPanel extends React.Component {
    state = {}

    render() {
        const {title} = this.props
        const {date} = this.state
        if (!date)
            return null
        return (
            <Panel
                className={styles.panel}
                type='modal'>
                <PanelHeader
                    icon='calendar-alt'
                    title={title}/>
                <PanelContent className={styles.panelContent}>
                    {this.renderYears()}
                    {this.renderMonths()}
                    {this.renderDays()}
                </PanelContent>
                <PanelButtons onEnter={() => this.select()} onEscape={() => this.close()}>
                    <PanelButtons.Main>
                        {this.renderButtons()}
                    </PanelButtons.Main>
                </PanelButtons>
            </Panel>
        )
    }

    renderYears() {
        const {startDate, endDate} = this.props
        const {date} = this.state
        const startYear = startDate.year()
        const endYear = endDate.year()
        const selectedYear = date.year()
        return (
            <ScrollableContainer className={styles.years}>
                <Scrollable>
                    {_.range(startYear, endYear + 1).map(year =>
                        <CalendarButton
                            key={year}
                            label={year}
                            selected={year === selectedYear}
                            className={styles.year}
                            onClick={() => this.updateDate('year', year)}/>
                    )}
                </Scrollable>
            </ScrollableContainer>
        )
    }

    renderMonths() {
        const {date} = this.state
        const {startDate, endDate} = this.props
        const months = moment.monthsShort()
        const selectedMonth = months[date.month()]
        const firstMonthIndex = date.year() === startDate.year() ? startDate.month() : 0
        const lastMonthIndex = date.year() === endDate.year() ? endDate.month() : 11
        return (
            <div className={styles.months}>
                {months.map((month, i) =>
                    <CalendarButton
                        key={month}
                        label={month}
                        selected={month === selectedMonth}
                        className={styles.month}
                        disabled={i < firstMonthIndex || i > lastMonthIndex}
                        onClick={() => this.updateDate('month', month)}/>
                )}
            </div>
        )
    }

    renderDays() {
        const {date} = this.state
        const {startDate, endDate} = this.props
        const firstOfMonth = moment(date).startOf('month')
        const firstOfWeek = moment(firstOfMonth).startOf('week')
        const lastOfMonth = moment(date).endOf('month')
        const firstDay = date.isSame(startDate, 'month') ? startDate.date() : 1
        const lastDay = date.isSame(endDate, 'month') ? endDate.date() : lastOfMonth.date()
        const indexOffset = firstOfMonth.day() - 1
        const firstIndex = firstDay + indexOffset
        const lastIndex = lastDay + indexOffset

        return (
            <div className={styles.days}>
                {moment.weekdaysShort().map(weekday =>
                    <Label key={weekday} msg={weekday}/>
                )}
                {_.times(35, (i) => {
                        const buttonDate = moment(firstOfWeek).add(i, 'day')
                        const dayOfMonth = buttonDate.format('DD')
                        return (
                            <CalendarButton
                                key={i}
                                label={dayOfMonth}
                                selected={buttonDate.isSame(date, 'day')}
                                className={styles.date}
                                disabled={i < firstIndex || i > lastIndex}
                                onClick={() => this.updateDate('date', dayOfMonth)}/>
                        )
                    }
                )}
            </div>
        )
    }

    renderButtons() {
        return this.isDirty()
            ? <React.Fragment>
                <PanelButtons.Cancel onClick={() => this.close()}/>
                <PanelButtons.Save onClick={() => this.select()}/>
            </React.Fragment>
            : <PanelButtons.Close onClick={() => this.close()}/>
    }

    componentDidMount() {
        const {date} = this.props
        this.setState({
            date: this.toValidRange(date)
        })
    }

    updateDate(unit, value) {
        this.setState(prevState => ({
            date: this.toValidRange(prevState.date.set(unit, value))
        }))

    }

    toValidRange(date) {
        const {startDate, endDate} = this.props
        return moment.max(moment.min(moment(date), moment(endDate)), moment(startDate))
    }

    select() {
        const {onSelect} = this.props
        this.isDirty() && onSelect && onSelect(this.state.date)
        this.close()
    }

    close() {
        const {activatable} = this.props
        activatable.deactivate()
    }

    isDirty() {
        return !this.props.date.isSame(this.state.date, 'day')
    }
}

class CalendarButton extends Component {
    element = React.createRef()

    render() {
        let {label, selected, disabled, className, onClick} = this.props
        return (
            <Button
                chromeless={!selected}
                look={selected ? 'highlight' : 'default'}
                disabled={disabled}
                additionalClassName={className}
                onClick={onClick}>
                <span ref={this.element}>{label}</span>
            </Button>
        )
    }

    componentDidMount() {
        this.element.current.parentNode.parentNode.scrollTop = this.element.current.parentNode.offsetTop
    }
}

CalendarButton.propTypes = {
    label: PropTypes.any,
    selected: PropTypes.any,
    className: PropTypes.any,
    onClick: PropTypes.any
}

const policy = () => ({_: 'allow'})
const id = ({id}) => id
const DatePickerPanel = activatable({id, policy, alwaysAllow: true})(
    _DatePickerPanel
)
